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
        guard let buidlTransport = client.transport as? ModularTransport else {
            throw BaseError(shortMessage: "The property client.transport is not the ModularTransport")
        }
        guard let webAuthnAccount = owner as? WebAuthnAccount else {
            throw BaseError(shortMessage: "The property owner is not the WebAuthnAccount")
        }

        let wallet = try await Self.createWallet(
            transport: buidlTransport,
            hexPublicKey: webAuthnAccount.credential.publicKey,
            version: version,
            name: name
        )

        self.init(client: client, owner: owner, wallet: wallet)
    }

    /// Configuration for the user operation.
    public var userOperation: UserOperationConfiguration? {
        get async {
            let minimumVerificationGasLimit = SmartAccountUtils.getMinimumVerificationGasLimit(
                deployed: await self.isDeployed(),
                chainId: client.chain.chainId
            )

            let config = UserOperationConfiguration { userOperation in
                let verificationGasLimit = BigInt(minimumVerificationGasLimit)
                let maxGasLimit = max(verificationGasLimit, userOperation.verificationGasLimit ?? BigInt(0))

                return EstimateUserOperationGasResult(preVerificationGas: nil,
                                                      verificationGasLimit: maxGasLimit,
                                                      callGasLimit: nil,
                                                      paymasterVerificationGasLimit: nil,
                                                      paymasterPostOpGasLimit: nil)
            }

            return config
        }
    }

    public func getAddress() -> String {
        return wallet.address ?? ""
    }

    public func encodeCalls(args: [EncodeCallDataArg]) -> String? {
        return Utils.encodeCallData(args: args)
    }

    public func getFactoryArgs() async throws -> (String, String)? {
        if await isDeployed() {
            return nil
        }

        guard let initCode = wallet.getInitCode() else {
            throw BaseError(shortMessage: "There is no the initCode (factory address and data)")
        }

        return Utils.parseFactoryAddressAndData(initCode: initCode)
    }

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

    public func getStubSignature<T: UserOperation>(userOp: T) -> String {
        return STUB_SIGNATURE
    }

    public func sign(hex: String) async throws -> String {
        let digest = Utils.toSha3Data(message: hex)
        let hash = getReplaySafeHash(
            chainId: client.chain.chainId,
            account: getAddress(),
            hash: HexUtils.dataToHex(digest)
        )

        do {
            let signResult = try await owner.sign(hex: hash)
            let signature = encodePackedForSignature(
                signResult: signResult,
                publicKey: owner.getAddress(),
                hasUserOpGas: false
            )
            return signature
        } catch let error as BaseError {
            throw error
        } catch {
            throw BaseError(shortMessage: "CircleSmartAccount.owner.sign(hex: \"\(hash)\") failure",
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    public func signMessage(message: String) async throws -> String {
        guard let messageHash = Utilities.hashPersonalMessage(Data(message.utf8)) else {
            throw BaseError(shortMessage: "Failed to hash message: \"\(message)\"")
        }

        let messageHashHex = HexUtils.dataToHex(messageHash)

        let digest = Utils.toSha3Data(message: messageHashHex)
        let hash = getReplaySafeHash(
            chainId: client.chain.chainId,
            account: getAddress(),
            hash: HexUtils.dataToHex(digest)
        )

        do {
            let signResult = try await owner.sign(hex: hash)
            let signature = encodePackedForSignature(
                signResult: signResult,
                publicKey: owner.getAddress(),
                hasUserOpGas: false
            )
            return signature
        } catch let error as BaseError {
            throw error
        } catch {
            throw BaseError(shortMessage: "CircleSmartAccount.owner.sign(hex: \"\(hash)\") failure",
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    public func signTypedData(typedData: String) async throws -> String {
        guard let typedData = try? EIP712Parser.parse(typedData),
              let typedDataHash = try? typedData.signHash() else {
            logger.passkeyAccount.error("typedData signHash failure")
            throw BaseError(shortMessage: "Failed to hash TypedData: \"\(typedData)\"")
        }

        let typedDataHashHex = HexUtils.dataToHex(typedDataHash)

        let digest = Utils.toSha3Data(message: typedDataHashHex)
        let hash = getReplaySafeHash(
            chainId: client.chain.chainId,
            account: getAddress(),
            hash: HexUtils.dataToHex(digest)
        )

        do {
            let signResult = try await owner.sign(hex: hash)
            let signature = encodePackedForSignature(
                signResult: signResult,
                publicKey: owner.getAddress(),
                hasUserOpGas: false
            )
            return signature
        } catch let error as BaseError {
            throw error
        } catch {
            throw BaseError(shortMessage: "CircleSmartAccount.owner.sign(hex: \"\(hash)\") failure",
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    public func signUserOperation(chainId: Int, userOp: UserOperationV07) async throws -> String {
        userOp.sender = getAddress()
        let userOpHash = try Utils.getUserOperationHash(
            chainId: chainId,
            entryPointAddress: EntryPoint.v07.address,
            userOp: userOp
        )

        let hash = Utils.hashMessage(hex: userOpHash)

        do {
            let signResult = try await owner.sign(hex: hash)
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
    func getReplaySafeHash(
        chainId: Int,
        account: String,
        hash: String,
        verifyingContract: String = CIRCLE_WEIGHTED_WEB_AUTHN_MULTISIG_PLUGIN
    ) -> String {
        // Get the prefix
        let messagePrefix = "0x1901"
        let prefix = HexUtils.hexToData(hex: messagePrefix) ?? .init()

        // Get the domainSeparatorHash
        let domainSeparatorTypeHash =
        Utils.toSha3Data(message: "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")

        var types: [ABI.Element.ParameterType] = [
            .bytes(length: 32),
            .bytes(length: 32),
            .uint(bits: 256),
            .address,
            .bytes(length: 32)
        ]
        var values: [Any] = [
            domainSeparatorTypeHash,
            Self.getModuleIdHash(),
            chainId,
            verifyingContract,
            Utils.pad(data: Utils.toData(value: account), isRight: true)
        ]

        var domainSeparator = Data()
        if let encoded = ABIEncoder.encode(types: types, values: values) {
            domainSeparator = encoded
        }
        let domainSeparatorHash = domainSeparator.sha3(.keccak256)

        // Get the structHash
        guard let bytes = try? HexUtils.hexToBytes(hex: hash) else {
            logger.passkeyAccount.error("Failed to decode the hash of getReplaySafeHash into UInt8 array.")
            return ""
        }

        types = [.bytes(length: 32), .bytes(length: 32)]
        values = [Self.getModuleTypeHash(), bytes]
        var structData = Data()
        if let encoded = ABIEncoder.encode(types: types, values: values) {
            structData = encoded
        }
        let structHash = structData.sha3(.keccak256)

        // Concat the prefix, domainSeparatorHash and domainSeparatorHash
        let replaySafeHash = (prefix + domainSeparatorHash + structHash).sha3(.keccak256)

        return HexUtils.dataToHex(replaySafeHash)
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

    static func getModuleIdHash() -> Data {
        let message = Utils.encodePacked(["Weighted Multisig Webauthn Plugin", "1.0.0"])

        return Utils.toSha3Data(message: message)
    }

    static func getModuleTypeHash() -> Data {
        return Utils.toSha3Data(message: "CircleWeightedWebauthnMultisigMessage(bytes32 hash)")
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
