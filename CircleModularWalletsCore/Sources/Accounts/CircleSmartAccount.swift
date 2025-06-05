//
// Copyright (c) 2025, Circle Internet Group, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import BigInt
import Web3Core
import web3swift

/// Creates a Circle smart account.
///
/// - Parameters:
///   - client: The client used to interact with the blockchain.
///   - owner: The owner account associated with the Circle smart account.
///   - version: The version of the Circle smart account. Default is CIRCLE_SMART_ACCOUNT_VERSION_V1.
///   - name: The wallet name assigned to the newly registered account defaults to the format: "passkey-yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
///
/// - Returns: The created Circle smart account.
public func toCircleSmartAccount<A: Account>(
    client: Client,
    owner: A,
    version: String = CIRCLE_SMART_ACCOUNT_VERSION_V1,
    name: String? = nil
) async throws -> CircleSmartAccount<A> where A.T == SignResult {
    let version = CIRCLE_SMART_ACCOUNT_VERSION[version] ?? version
    let name = name ?? "passkey-\(Utils.getCurrentDateTime())"
    return try await .init(client: client, owner: owner, version: version, name: name)
}

/// A Circle smart account.
public class CircleSmartAccount<A: Account>: SmartAccount, @unchecked Sendable where A.T == SignResult {
    public let client: Client
    public let entryPoint: EntryPoint
    let owner: A
    let wallet: ModularWallet
    private var deployed: Bool = false
    private let nonceManager = NonceManager(source: NonceManagerSourceImpl())

    /// Initialize function for CircleSmartAccount
    ///
    /// - Parameters:
    ///   - client: The client used to interact with the blockchain.
    ///   - owner: The owner account associated with the Circle smart account.
    ///   - wallet: The created wallet information.
    ///   - entryPoint: The entry point for the smart account. Default is ``EntryPoint.v07``.
    init(client: Client, owner: A, wallet: ModularWallet, entryPoint: EntryPoint = .v07) {
        self.client = client
        self.owner = owner
        self.wallet = wallet
        self.entryPoint = entryPoint
    }

    convenience init(client: Client, owner: A, version: String, name: String?) async throws {
        guard let bundlerTransport = client.transport as? ModularTransport else {
            throw BaseError(shortMessage: "The property client.transport is not the ModularTransport")
        }
        guard let webAuthnAccount = owner as? WebAuthnAccount else {
            throw BaseError(shortMessage: "The property owner is not the WebAuthnAccount")
        }

        let wallet = try await Self.createWallet(
            transport: bundlerTransport,
            hexPublicKey: webAuthnAccount.credential.publicKey,
            version: version,
            name: name
        )

        self.init(client: client, owner: owner, wallet: wallet)
    }

    /// Configuration for the user operation.
    public var userOperation: UserOperationConfiguration? {
        get async {
            let config = UserOperationConfiguration { userOperation in
                // Only call getDefaultVerificationGasLimit if verificationGasLimit is not provided
                let verificationGasLimit = userOperation.verificationGasLimit != nil ?
                userOperation.verificationGasLimit : await SmartAccountUtils.getDefaultVerificationGasLimit(
                    client: self.client,
                    deployed: await self.isDeployed()
                )

                return EstimateUserOperationGasResult(
                    preVerificationGas: nil,
                    verificationGasLimit: verificationGasLimit,
                    callGasLimit: nil,
                    paymasterVerificationGasLimit: nil,
                    paymasterPostOpGasLimit: nil
                )
            }

            return config
        }
    }

    /// Returns the address of the account.
    ///
    /// - Returns: The address of the smart account.
    public func getAddress() -> String {
        return wallet.address ?? ""
    }

    /// Encodes the given call data arguments.
    ///
    /// - Parameters:
    ///   - args: The call data arguments to encode.
    ///
    /// - Returns: The encoded call data.
    public func encodeCalls(args: [EncodeCallDataArg]) -> String? {
        return Utils.encodeCallData(args: args)
    }

    /// Encodes the given call data arguments.
    ///
    /// - Parameters:
    ///   - args: The call data arguments to encode.
    ///
    /// - Returns: The encoded call data.
    public func getFactoryArgs() async throws -> (String, String)? {
        if await isDeployed() {
            return nil
        }

        guard let initCode = wallet.getInitCode() else {
            throw BaseError(shortMessage: "There is no the initCode (factory address and data)")
        }

        return Utils.parseFactoryAddressAndData(initCode: initCode)
    }

    /// Returns the nonce for the Circle smart account.
    ///
    /// - Parameters:
    ///   - key: An optional key to retrieve the nonce for.
    ///
    /// - Returns: The nonce of the Circle smart account.
    public func getNonce(key: BigInt?) async throws -> BigInt {
        let _key: BigInt
        if let key = key {
            _key = key
        } else {
            let _keyStr = await nonceManager.consume(
                params: FunctionParameters(address: getAddress(),
                                           chainId: client.chain.chainId)
            )

            guard let bigInt = BigInt(_keyStr) else {
                throw BaseError(shortMessage: "Cannot convert BigInt(\(_keyStr) to BigInt")
            }

            _key = bigInt
        }

        guard _key >= BigInt(0) else {
            throw BaseError(shortMessage: "Cannot convert negative BigInt(\(_key) to BigUInt")
        }

        let nonce = try await Utils.getNonce(transport: client.transport,
                                             address: getAddress(),
                                             entryPoint: entryPoint,
                                             key: BigUInt(_key))
        return nonce
    }

    /// Returns the stub signature for the given user operation.
    ///
    /// - Parameters:
    ///   - userOp: The user operation to retrieve the stub signature for. The type `T` must be a subclass of `UserOperation`.
    ///
    /// - Returns: The stub signature.
    public func getStubSignature<T: UserOperation>(userOp: T) -> String {
        return STUB_SIGNATURE
    }

    /// Signs a hash via the Smart Account's owner.
    ///
    /// - Parameters:
    ///   - messageHash: The hash to sign.
    ///
    /// - Returns: The signed data.
    public func sign(messageHash: String) async throws -> String {
        let replaySafeMessageHash = try await Utils.getReplaySafeMessageHash(
            transport: client.transport,
            account: getAddress(),
            hash: messageHash
        )

        do {
            let signResult = try await owner.sign(messageHash: replaySafeMessageHash)
            let signature = encodePackedForSignature(
                signResult: signResult,
                publicKey: owner.getAddress(),
                hasUserOpGas: false
            )
            return signature
        } catch let error as BaseError {
            throw error
        } catch {
            throw BaseError(shortMessage: "CircleSmartAccount.owner.sign(hash: \"\(replaySafeMessageHash)\") failure",
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    /// Signs a [EIP-191 Personal Sign message](https://eips.ethereum.org/EIPS/eip-191).
    ///
    /// - Parameters:
    ///   - message: The message to sign.
    ///
    /// - Returns: The signed message.
    public func signMessage(message: String) async throws -> String {
        guard let hashedMessageData = Utilities.hashPersonalMessage(Data(message.utf8)) else {
            throw BaseError(shortMessage: "Failed to hash message: \"\(message)\"")
        }

        let hashedMessage = HexUtils.dataToHex(hashedMessageData)
        let replaySafeMessageHash = try await Utils.getReplaySafeMessageHash(
            transport: client.transport,
            account: getAddress(),
            hash: hashedMessage
        )

        do {
            let signResult = try await owner.sign(messageHash: replaySafeMessageHash)
            let signature = encodePackedForSignature(
                signResult: signResult,
                publicKey: owner.getAddress(),
                hasUserOpGas: false
            )
            return signature
        } catch let error as BaseError {
            throw error
        } catch {
            throw BaseError(shortMessage: "CircleSmartAccount.owner.sign(hash: \"\(replaySafeMessageHash)\") failure",
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    /// Signs a given typed data.
    ///
    /// - Parameters:
    ///   - typedData: The typed data to sign.
    ///
    /// - Returns: The signed typed data.
    public func signTypedData(typedData: String) async throws -> String {
        guard let typedData = try? EIP712Parser.parse(typedData),
              let hashedTypedDataData = try? typedData.signHash() else {
            logger.passkeyAccount.error("typedData signHash failure")
            throw BaseError(shortMessage: "Failed to hash TypedData: \"\(typedData)\"")
        }

        let hashedTypedData = HexUtils.dataToHex(hashedTypedDataData)
        let replaySafeMessageHash = try await Utils.getReplaySafeMessageHash(
            transport: client.transport,
            account: getAddress(),
            hash: hashedTypedData
        )

        do {
            let signResult = try await owner.sign(messageHash: replaySafeMessageHash)
            let signature = encodePackedForSignature(
                signResult: signResult,
                publicKey: owner.getAddress(),
                hasUserOpGas: false
            )
            return signature
        } catch let error as BaseError {
            throw error
        } catch {
            throw BaseError(shortMessage: "CircleSmartAccount.owner.sign(hash: \"\(replaySafeMessageHash)\") failure",
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    /// Signs a given user operation.
    ///
    /// - Parameters:
    ///   - chainId: The chain ID for the user operation. Default is the chain ID of the client.
    ///   - userOp: The user operation to sign.
    ///
    /// - Returns: The signed user operation.
    public func signUserOperation(chainId: Int, userOp: UserOperationV07) async throws -> String {
        userOp.sender = getAddress()
        let userOpHash = try Utils.getUserOperationHash(
            chainId: chainId,
            entryPointAddress: EntryPoint.v07.address,
            userOp: userOp
        )

        let hash = Utils.hashMessage(hex: userOpHash)

        do {
            let signResult = try await owner.sign(messageHash: hash)
            let signature = encodePackedForSignature(
                signResult: signResult,
                publicKey: owner.getAddress(),
                hasUserOpGas: true
            )
            return signature
        } catch let error as BaseError {
            throw error
        } catch {
            throw BaseError(shortMessage: "CircleSmartAccount.owner.sign(hex: hash(\"\(userOpHash)\")) failure",
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    /// Returns the initialization code for the Circle smart account.
    ///
    /// - Returns: The initialization code.
    public func getInitCode() -> String? {
        return wallet.getInitCode()
    }
}

extension CircleSmartAccount: PublicRpcApi {

    // MARK: Internal Usage

    static func createWallet(
        transport: ModularTransport,
        hexPublicKey: String,
        version: String,
        name: String? = nil
    ) async throws -> ModularWallet {
        let (publicKeyX, publicKeyY) = Self.extractXYFromCOSE(hexPublicKey)
        let request = GetAddressReq(
            scaConfiguration: ScaConfiguration(
                initialOwnershipConfiguration: .init(
                    ownershipContractAddress: nil,
                    weightedMultiSig: .init(
                        owners: nil,
                        webauthnOwners: [.init(publicKeyX: publicKeyX.description,
                                               publicKeyY: publicKeyY.description,
                                               weight: PUBLIC_KEY_OWN_WEIGHT)],
                        thresholdWeight: THRESHOLD_WEIGHT)
                ),
                scaCore: version,
                initCode: nil),
            metadata: .init(name: name)
        )

        let wallet = try await transport.getAddress(transport: transport, req: request)

        return wallet
    }

    /// Checks if the account is deployed.
    ///
    /// - Returns: `true` if the account is deployed, `false` otherwise.
    private func isDeployed() async -> Bool {
        if deployed { return true }
        do {
            let byteCode = try await getCode(transport: client.transport,
                                             address: getAddress())
            let isEmpty = try HexUtils.hexToBytes(hex: byteCode).isEmpty
            deployed = !isEmpty
            return deployed
        } catch {
            return false
        }
    }

    /// Remove the private access control for unit testing
    func encodePackedForSignature(
        signResult: SignResult,
        publicKey: String,
        hasUserOpGas: Bool
    ) -> String {
        let pubKey = Self.extractXYFromCOSE(publicKey)
        let sender = Self.getSender(x: pubKey.0, y: pubKey.1)

        let formattedSender = Self.getFormattedSender(sender: sender)
        let sigType: UInt8 = hasUserOpGas ? 34 : 2
        let sigBytes = encodeWebAuthnSigDynamicPart(signResult: signResult)

        let encoded = Utils.encodePacked([
            formattedSender,
            /// dynamicPos
            /// 32-bytes public key onchain id
            /// 32-bytes webauth, signature and public key position
            /// 1-byte signature type
            /// https://github.com/circlefin/buidl-wallet-contracts/blob/7388395fac2ac8bcd19af9a1caaac5df3c4813f2/docs/Smart_Contract_Signatures_Encoding.md#sigtype--2
            65,
            sigType,
            sigBytes.count,
            sigBytes
        ]).addHexPrefix()

        return encoded
    }

    private func encodeWebAuthnSigDynamicPart(signResult: SignResult) -> Data {
        guard let (rData, sData) = Utils.extractRSFromDER(signResult.signature) else {
            logger.passkeyAccount.notice("Can't extract the r, s from a DER-encoded ECDSA signature")
            return .init()
        }

        let (r, s) = (BigUInt(rData), BigUInt(sData))

        let encoded = Self.encodeParametersWebAuthnSigDynamicPart(
            authenticatorDataString: signResult.webAuthn.authenticatorData,
            clientDataJSON: signResult.webAuthn.clientDataJSON,
            challengeIndex: signResult.webAuthn.challengeIndex,
            typeIndex: signResult.webAuthn.typeIndex,
            userVerificationRequired: signResult.webAuthn.userVerificationRequired,
            r: r,
            s: s
        )

        return encoded
    }

    static func encodeParametersWebAuthnSigDynamicPart(
        authenticatorDataString: String,    // Hex
        clientDataJSON: String,             // Base64URL decoded
        challengeIndex: Int,
        typeIndex: Int,
        userVerificationRequired: Bool,
        r: BigUInt,
        s: BigUInt
    ) -> Data {
        let types: [ABI.Element.ParameterType] = [
            .tuple(types: [
                .tuple(types: [
                    .dynamicBytes,
                    .string,
                    .uint(bits: 256),
                    .uint(bits: 256),
                    .bool]),
                .uint(bits: 256),
                .uint(bits: 256)
            ])
        ]

        var authenticatorData = [UInt8]()
        if let _authenticatorData = try? HexUtils.hexToBytes(hex: authenticatorDataString) {
            authenticatorData = _authenticatorData
        }

        let values: [Any] = [
            [
                [
                    authenticatorData,
                    clientDataJSON,
                    BigUInt(challengeIndex),
                    BigUInt(typeIndex),
                    userVerificationRequired
                ],
                r,
                s
            ]
        ]

        var encoded = Data()
        if let _encoded = ABIEncoder.encode(types: types, values: values) {
            encoded = _encoded
        }

        return encoded
    }

    private static func extractXYFromCOSE(_ keyHex: String) -> (BigUInt, BigUInt) {
        let xy = Self.extractXYFromCOSEBytes(keyHex)
        return (BigUInt(Data(xy.0)), BigUInt(Data(xy.1)))
    }

    private static func extractXYFromCOSEBytes(_ keyHex: String) -> ([UInt8], [UInt8]) {

        guard let bytes = try? HexUtils.hexToBytes(hex: keyHex) else {
            logger.passkeyAccount.error("Failed to decode the publicKey (COSE_Key format) hex string into UInt8 array.")
            return (.init(), .init())
        }

        // EC2 key type
        guard bytes.count == 77 else {
            logger.passkeyAccount.error("Insufficient bytes length; does not comply with COSE Key format EC2 key type.")
            return (.init(), .init())
        }

        let offset = 10

        let x = Array(bytes[offset..<(offset + 32)])
        let y = Array(bytes[(offset + 32 + 3)..<(offset + 64 + 3)])

        return (x, y)
    }

    static func getSender(x: BigUInt, y: BigUInt) -> String {
        let encoded = encodeParametersGetSender(x, y)
        let hash = encoded.sha3(.keccak256)
        return HexUtils.dataToHex(hash)
    }

    static func encodeParametersGetSender(_ x: BigUInt, _ y: BigUInt) -> Data {
        let types: [ABI.Element.ParameterType] = [
            .uint(bits: 256),
            .uint(bits: 256)
        ]
        let values = [x, y]

        let encoded = ABIEncoder.encode(types: types, values: values) ?? Data()

        return encoded
    }

    static func getFormattedSender(sender: String) -> [UInt8] {
        func slice(value: String,
                   start: Int? = nil,
                   end: Int? = nil,
                   strict: Bool = false) -> String {
            let cleanValue = value.noHexPrefix
            let startIndex = (start ?? 0) * 2
            let endIndex = (end ?? (cleanValue.count / 2)) * 2

            guard startIndex >= 0, endIndex <= cleanValue.count, startIndex <= endIndex else {
                logger.passkeyAccount.notice("Return \"0x\" if indices are invalid")
                return "0x"
            }

            let slicedValue = "0x" + cleanValue[startIndex..<endIndex]
            
            // This block is never executed because the `strict` parameter is always set to its default value (`false`).
//            if strict {
//                guard slicedValue.range(of: "^0x[0-9a-fA-F]*$", options: .regularExpression) != nil else {
//                    logger.passkeyAccount.notice("Invalid hexadecimal string")
//                    return "0x"
//                }
//            }

            return slicedValue
        }

        let slicedSender = slice(value: sender, start: 2)
        let paddedSlicedSender = slicedSender.noHexPrefix.leftPadding(toLength: 32 * 2, withPad: "0").addHexPrefix()

        guard let formattedSender = try? HexUtils.hexToBytes(hex: paddedSlicedSender) else {
            logger.passkeyAccount.error("Failed to get formatted sender")
            return .init()
        }

        return formattedSender
    }
}
