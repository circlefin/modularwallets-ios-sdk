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
public func toCircleSmartAccount(
    client: Client,
    owner: WebAuthnAccount,
    version: String = CIRCLE_SMART_ACCOUNT_VERSION_V1,
    name: String? = nil
) async throws -> CircleSmartAccount {
    let version = CIRCLE_SMART_ACCOUNT_VERSION[version] ?? version
    let name = name ?? Utils.getDefaultWalletName(prefix: WebAuthnCircleSmartAccountDelegate.WALLET_PREFIX)
    return try await .init(client: client, owner: owner, version: version, name: name)
}

/// Creates a Circle smart account.
///
/// - Parameters:
///   - client: The client used to interact with the blockchain.
///   - owner: The owner account associated with the Circle smart account.
///   - version: The version of the Circle smart account. Default is CIRCLE_SMART_ACCOUNT_VERSION_V1.
///   - name: The wallet name assigned to the newly registered account defaults to the format: "wallet-yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
///
/// - Returns: The created Circle smart account.
public func toCircleSmartAccount(
    client: Client,
    owner: LocalAccount,
    version: String = CIRCLE_SMART_ACCOUNT_VERSION_V1,
    name: String? = nil
) async throws -> CircleSmartAccount {
    let version = CIRCLE_SMART_ACCOUNT_VERSION[version] ?? version
    let name = name ?? Utils.getDefaultWalletName(prefix: LocalCircleSmartAccountDelegate.WALLET_PREFIX)
    return try await .init(client: client, owner: owner, version: version, name: name)
}

/// A Circle smart account.
public class CircleSmartAccount: SmartAccount, @unchecked Sendable {
    public let client: Client
    public let entryPoint: EntryPoint
    let delegate: CircleSmartAccountDelegate
    let wallet: ModularWallet
    private var deployed: Bool = false
    private let nonceManager = NonceManager(source: NonceManagerSourceImpl())

    /// Initialize function for CircleSmartAccount
    ///
    /// - Parameters:
    ///   - client: The client used to interact with the blockchain.
    ///   - delegate: The delegate for Circle smart account operations.
    ///   - wallet: The created wallet information.
    ///   - entryPoint: The entry point for the smart account. Default is ``EntryPoint.v07``.
    init(client: Client, delegate: CircleSmartAccountDelegate, wallet: ModularWallet, entryPoint: EntryPoint = .v07) {
        self.client = client
        self.delegate = delegate
        self.wallet = wallet
        self.entryPoint = entryPoint
    }

    convenience init(client: Client, owner: WebAuthnAccount, version: String, name: String?) async throws {
        guard let bundlerTransport = client.transport as? ModularTransport else {
            throw BaseError(shortMessage: "The property client.transport is not the ModularTransport (found \(type(of: client.transport)))")
        }

        let delegate = WebAuthnCircleSmartAccountDelegate(owner)

        let wallet = try await delegate.getModularWalletAddress(
            transport: bundlerTransport,
            version: version,
            name: name
        )

        self.init(client: client, delegate: delegate, wallet: wallet)
    }

    convenience init(client: Client, owner: LocalAccount, version: String, name: String?) async throws {
        guard let bundlerTransport = client.transport as? ModularTransport else {
            throw BaseError(shortMessage: "The property client.transport is not the ModularTransport (found \(type(of: client.transport)))")
        }

        let delegate = LocalCircleSmartAccountDelegate(owner)

        let wallet = try await delegate.getModularWalletAddress(
            transport: bundlerTransport,
            version: version,
            name: name
        )

        self.init(client: client, delegate: delegate, wallet: wallet)
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

        return try await delegate.signAndWrap(hash: replaySafeMessageHash, hasUserOpGas: false)
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

        return try await delegate.signAndWrap(hash: replaySafeMessageHash, hasUserOpGas: false)
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

        return try await delegate.signAndWrap(hash: replaySafeMessageHash, hasUserOpGas: false)
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

        return try await delegate.signAndWrap(hash: userOpHash, hasUserOpGas: true)
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
}
