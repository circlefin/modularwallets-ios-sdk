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
import Web3Core
import BigInt

/// A Bundler Client is an interface to interact with ERC-4337 Bundlers and provides the ability to send and retrieve User Operations through Bundler Actions.
public class BundlerClient: Client, BundlerRpcApi, PublicRpcApi {

    /// Estimates the gas values for a User Operation to be executed successfully.
    ///
    /// - Parameters:
    ///   - account: The Account to use for User Operation execution.
    ///   - calls: The calls to execute in the User Operation.
    ///   - paymaster: Sets Paymaster configuration for the User Operation.
    ///   - estimateFeesPerGas: Prepares fee properties for the User Operation request.
    ///
    /// - Returns: The estimated gas values for the User Operation.
    public func estimateUserOperationGas(
        account: SmartAccount,
        calls: [EncodeCallDataArg],
        paymaster: Paymaster? = nil,
        estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)?
    ) async throws -> EstimateUserOperationGasResult {
        let userOp = try await self.prepareUserOperation(
            transport: transport,
            account: account,
            calls: calls,
            partialUserOp: UserOperationV07(),
            paymaster: paymaster,
            bundlerClient: self,
            estimateFeesPerGas: estimateFeesPerGas
        )
        return try await self.estimateUserOperationGas(transport: transport, userOp: userOp, entryPoint: account.entryPoint)
    }

    /// Returns the chain ID associated with the current network.
    ///
    /// - Returns: The current chain ID.
    public func getChainId() async throws -> Int {
        try await self.getChainId(transport: transport)
    }

    /// Returns the EntryPoints that the bundler supports.
    ///
    /// - Returns: The EntryPoints that the bundler supports.
    public func getSupportedEntryPoints() async throws -> [String] {
        try await self.getSupportedEntryPoints(transport: transport)
    }

    /// Retrieves information about a User Operation given a hash.
    ///
    /// - Parameter userOpHash: User Operation hash.
    /// - Returns: User Operation information.
    public func getUserOperation(userOpHash: String) async throws -> GetUserOperationResult {
        try await self.getUserOperation(transport: transport, userOpHash: userOpHash)
    }

    /// Returns the User Operation Receipt given a User Operation hash.
    ///
    /// - Parameter userOpHash: User Operation hash.
    /// - Returns: The User Operation receipt.
    public func getUserOperationReceipt(userOpHash: String) async throws -> GetUserOperationReceiptResult {
        try await self.getUserOperationReceipt(transport: transport, userOpHash: userOpHash)
    }

    /// Prepares a User Operation for execution and fills in missing properties.
    ///
    /// - Parameters:
    ///   - account: The Account to use for User Operation execution.
    ///   - calls: The calls to execute in the User Operation.
    ///   - partialUserOp: The partial User Operation to be completed.
    ///   - paymaster: Sets Paymaster configuration for the User Operation.
    ///   - estimateFeesPerGas: Prepares fee properties for the User Operation request.
    ///
    /// - Returns: The prepared User Operation.
    public func prepareUserOperation(
        account: SmartAccount,
        calls: [EncodeCallDataArg]?,
        partialUserOp: UserOperationV07,
        paymaster: Paymaster? = nil,
        estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
    ) async throws -> UserOperationV07 {
        try await self.prepareUserOperation(transport: transport, account: account, calls: calls, partialUserOp: partialUserOp, paymaster: paymaster, bundlerClient: self, estimateFeesPerGas: estimateFeesPerGas)
    }

    /// Broadcasts a User Operation to the Bundler.
    ///
    /// - Parameters:
    ///   - account: The Account to use for User Operation execution.
    ///   - calls: The calls to execute in the User Operation.
    ///   - partialUserOp: The partial User Operation to be completed.
    ///   - paymaster: Sets Paymaster configuration for the User Operation.
    ///   - estimateFeesPerGas: Prepares fee properties for the User Operation request.
    ///
    /// - Returns: The hash of the sent User Operation.
    public func sendUserOperation(
        account: SmartAccount,
        calls: [EncodeCallDataArg]?,
        partialUserOp: UserOperationV07 = .init(),
        paymaster: Paymaster? = nil,
        estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
    ) async throws -> String {
        if !(partialUserOp.signature?.isEmpty ?? true) {
            return try await self.sendUserOperation(
                transport: transport,
                partialUserOp: partialUserOp,
                entryPointAddress: account.entryPoint.address
            )
        }

        let userOp = try await self.prepareUserOperation(
            transport: transport,
            account: account,
            calls: calls,
            partialUserOp: partialUserOp,
            paymaster: paymaster,
            bundlerClient: self,
            estimateFeesPerGas: estimateFeesPerGas
        )

        userOp.signature = try await account.signUserOperation(
            chainId: chain.chainId,
            userOp: userOp
        )

        return try await self.sendUserOperation(
            transport: transport,
            partialUserOp: userOp,
            entryPointAddress: account.entryPoint.address
        )
    }

    /// Waits for the User Operation to be included on a Block (one confirmation), and then returns the User Operation receipt.
    ///
    /// - Parameters:
    ///   - userOpHash: A User Operation hash.
    ///   - pollingInterval: Polling frequency (in ms).
    ///   - retryCount: The number of times to retry.
    ///   - timeout: Optional timeout (in ms) to wait before stopping polling.
    ///
    /// - Returns: The User Operation receipt.
    public func waitForUserOperationReceipt(
        userOpHash: String,
        pollingInterval: Int = 4000,
        retryCount: Int = 6,
        timeout: Int? = nil
    ) async throws -> GetUserOperationReceiptResult {
        try await self.waitForUserOperationReceipt(transport: transport, userOpHash: userOpHash, pollingInterval: pollingInterval, retryCount: retryCount, timeout: timeout)
    }

    /// Retrieves the balance of the specified address at a given block tag.
    ///
    /// - Parameters:
    ///   - address: The address to query the balance for. Only wallet addresses that registered with the using client key can be retrieved.
    ///   - blockNumber: The balance of the account at a block number.
    ///
    /// - Returns: The balance of the address in wei.
    public func getBalance(
        address: String,
        blockNumber: BlockNumber = .latest
    ) async throws -> BigInt {
        let result = try await getBalance(transport: transport,
                                          address: address,
                                          blockNumber: blockNumber)
        return result
    }

    /// Returns the number of the most recent block seen.
    ///
    /// - Returns: The number of the block.
    public func getBlockNumber() async throws -> BigInt {
        let result = try await getBlockNum(transport: transport)
        return result
    }

    /// Returns the current price of gas (in wei).
    ///
    /// - Returns: The gas price (in wei).
    public func getGasPrice() async throws -> BigInt {
        let result = try await getGasPrice(transport: transport)
        return result
    }

    /// Executes a new message call immediately without submitting a transaction to the network.
    ///
    /// - Parameters:
    ///   - from: The Account to call from.
    ///   - to: The contract address or recipient.
    ///   - data: A contract hashed method call with encoded args.
    ///
    /// - Returns: The result of the call.
    public func call(from: String?, to: String, data: Data) async throws -> String {
        var fromAddress: EthereumAddress?
        if let from {
            fromAddress = EthereumAddress(from)
        }

        guard let toAddress = EthereumAddress(to) else {
            throw BaseError(shortMessage: "EthereumAddress initialization failed")
        }

        var transaction = CodableTransaction(to: toAddress, data: data)
        transaction.from = fromAddress

        return try await ethCall(transport: transport, transaction: transaction)
    }

    /// Retrieves the byte code at an address.
    ///
    /// - Parameters:
    ///   - address: The contract address.
    ///   - blockTag: The block tag to perform the byte code read against.
    ///
    /// - Returns: The code of the specified address at the given block tag.
    public func getCode(
        address: String,
        blockNumber: BlockNumber = .latest
    ) async throws -> String {
        return try await getCode(transport: transport,
                                 address: address,
                                 blockNumber: blockNumber)
    }

    /// Returns an estimate for the max priority fee per gas (in wei) for a transaction to be likely included in the next block.
    /// The action will either call `eth_maxPriorityFeePerGas` (if supported) or manually calculate the max priority fee per gas based on the current block base fee per gas + gas price.
    ///
    /// - Returns: An estimate (in wei) for the max priority fee per gas.
    public func estimateMaxPriorityFeePerGas() async throws -> BigInt {
        return try await getMaxPriorityFeePerGas(transport: transport)
    }

    /// Returns information about a block at a given block number.
    ///
    /// - Parameters:
    ///   - includeTransactions: Whether or not to include transactions (as a structured array of Transaction objects). Default is false.
    ///   - blockNumber: The block number to query the information for.
    ///
    /// - Returns: Information about the block.
    public func getBlock(
        includeTransactions: Bool = false,
        blockNumber: BlockNumber = .latest
    ) async throws -> Block {
        return try await getBlock(transport: transport,
                                  includeTransactions: includeTransactions,
                                  blockNumber: blockNumber)
    }
    
    /// Creates an address mapping for recovery.
    ///
    /// - Note: This feature is only available in Circle Buidl Wallets service.
    ///
    /// - Parameters:
    ///   - walletAddress: The Circle smart wallet address.
    ///   - owners: The owners of the wallet.
    /// - Returns: The response from adding an address mapping.
    public func createAddressMapping(
        walletAddress: String,
        owners: [AddressMappingOwner]
    ) async throws -> [AddressMappingResult] {
        guard let bundlerTransport = transport as? ModularTransport else {
            throw BaseError(shortMessage: "The property transport is not the ModularTransport")
        }

        return try await bundlerTransport.createAddressMapping(
            transport: bundlerTransport,
            walletAddress: walletAddress,
            owners: owners
        )
    }
    
    /// Gets the address mapping for a given owner.
    ///
    /// - Note: This feature is only available in Circle Buidl Wallets service.
    ///
    /// - Parameter owner: The owner information.
    /// - Returns: An array of address mappings associated with the given owner.
    public func getAddressMapping(
        owner: AddressMappingOwner
    ) async throws -> [AddressMappingResult] {
        guard let bundlerTransport = transport as? ModularTransport else {
            throw BaseError(shortMessage: "The property transport is not the ModularTransport")
        }

        return try await bundlerTransport.getAddressMapping(
            transport: bundlerTransport,
            owner: owner
        )
    }
    
    /// Estimates the gas required to register a recovery address during the recovery process.
    ///
    /// - Parameters:
    ///   - account: The Account to use for User Operation execution.
    ///   - recoveryAddress: The derived address of the recovery key.
    ///   - partialUserOp: A partially constructed UserOperation object that can include custom gas parameters.
    ///                    The `callData` field, if provided, will be **overwritten internally**
    ///                    with the encoded `addOwners` call data based on `recoveryAddress`.
    ///   - paymaster: Sets Paymaster configuration for the User Operation.
    ///   - estimateFeesPerGas: Prepares fee properties for the User Operation request.
    ///
    /// - Returns: An estimate of gas values necessary to register a recovery address.
    public func estimateRegisterRecoveryAddressGas(
        account: SmartAccount,
        recoveryAddress: String,
        partialUserOp: UserOperationV07 = UserOperationV07(),
        paymaster: Paymaster? = nil,
        estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
    ) async throws -> EstimateUserOperationGasResult {
        if !Utils.isAddress(recoveryAddress) {
            throw BaseError(shortMessage: "Invalid recovery address format")
        }

        logger.bundler.debug("Estimating gas for registering recovery address \(recoveryAddress) for account \(account.getAddress())")

        let addOwnersData = try Utils.getAddOwnersData(ownerToAdd: recoveryAddress)

        let updatedUserOp = partialUserOp
        updatedUserOp.callData = addOwnersData
        let userOp = try await prepareUserOperation(
            transport: transport,
            account: account,
            calls: nil,
            partialUserOp: updatedUserOp,
            paymaster: paymaster,
            bundlerClient: self,
            estimateFeesPerGas: estimateFeesPerGas
        )

        return try await estimateUserOperationGas(
            transport: transport,
            userOp: userOp,
            entryPoint: account.entryPoint
        )
    }

    /// Estimates the gas required to execute and finalize the recovery process.
    ///
    /// - Parameters:
    ///   - account: The Account to use for User Operation execution.
    ///   - credential: The newly registered passkey credential.
    ///   - partialUserOp: A partially constructed UserOperation object that can include custom gas parameters.
    ///                    The `callData` field, if provided, will be **overwritten internally**
    ///                    with the encoded `addOwners` call data based on `credential`.
    ///   - paymaster: Sets Paymaster configuration for the User Operation.
    ///   - estimateFeesPerGas: Prepares fee properties for the User Operation request.
    ///
    /// - Returns: An estimate of gas values necessary to execute recovery.
    public func estimateExecuteRecoveryGas(
            account: SmartAccount,
            credential: WebAuthnCredential,
            partialUserOp: UserOperationV07 = UserOperationV07(),
            paymaster: Paymaster? = nil,
            estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
    ) async throws -> EstimateUserOperationGasResult {
        let addOwnersData = try Utils.getAddOwnersData(credential: credential)

        let updatedUserOp = partialUserOp
        updatedUserOp.callData = addOwnersData
        let userOp = try await prepareUserOperation(
            transport: transport,
            account: account,
            calls: nil,
            partialUserOp: updatedUserOp,
            paymaster: paymaster,
            bundlerClient: self,
            estimateFeesPerGas: estimateFeesPerGas
        )

        return try await estimateUserOperationGas(
            transport: transport,
            userOp: userOp,
            entryPoint: account.entryPoint
        )
    }

    /// Registers a recovery address for a Smart Account.
    ///
    /// - Parameters:
    ///   - account: The Account to use for User Operation execution.
    ///   - recoveryAddress: The recovery address to register.
    ///   - partialUserOp: The partial User Operation to be completed.
    ///   - paymaster: Sets Paymaster configuration for the User Operation.
    ///   - estimateFeesPerGas: Prepares fee properties for the User Operation request.
    ///
    /// - Returns: The hash of the sent User Operation.
    public func registerRecoveryAddress(
        account: SmartAccount,
        recoveryAddress: String,
        partialUserOp: UserOperationV07 = UserOperationV07(),
        paymaster: Paymaster? = nil,
        estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
    ) async throws -> String? {
        if !Utils.isAddress(recoveryAddress) {
            throw BaseError(shortMessage: "Invalid recovery address format: \(recoveryAddress)")
        }

        logger.bundler.debug("Registering recovery address \(recoveryAddress) for account \(account.getAddress())")

        // Step 1: Create a mapping between the MSCA address and the recovery address
        let owners: [AddressMappingOwner] = [
            EoaAddressMappingOwner(EOAIdentifier(address: recoveryAddress))
        ]

        do {
            _ = try await createAddressMapping(
                walletAddress: account.getAddress(),
                owners: owners
            )
            logger.bundler.debug("Off-chain address mapping created successfully")
        } catch let error as InvalidParamsRpcError {
            /// Ignore "address mapping already exists" errors to ensure idempotency and allow safe retries.
            /// This prevents inconsistent states between RPC calls and onchain transactions.
            if !ErrorUtils.isMappedError(error) {
                throw BaseError(
                    shortMessage: "Failed to register the recovery address. Please try again.",
                    args: BaseErrorParameters(cause: error)
                )
            }
        }

        // Step 2: Encode the function call for the userOp
        let addOwnersData = try Utils.getAddOwnersData(ownerToAdd: recoveryAddress)

        // Step 3: Send user operation to store the recovery address onchain
        do {
            let updatedUserOp = partialUserOp
            updatedUserOp.callData = addOwnersData

            return try await sendUserOperation(
                account: account,
                calls: nil,     // Set to nil since callData is assigned directly
                partialUserOp: updatedUserOp,
                paymaster: paymaster,
                estimateFeesPerGas: estimateFeesPerGas
            )
        } catch let error as UserOperationExecutionError {
            if error.details == ExecutionRevertedError.message {
                let isOwner = try await Utils.isOwnerOf(
                    transport: transport,
                    account: account.getAddress(),
                    ownerToCheck: recoveryAddress
                )
                if isOwner {
                    return nil
                }
            }
            throw error
        }
    }

    /// Executes and finalizes the recovery process.
    ///
    /// - Parameters:
    ///   - account: The Account to use for User Operation execution.
    ///   - credential: The newly registered passkey credential.
    ///   - partialUserOp: A partially constructed UserOperation object.
    ///                    The `callData` field, if provided, will be **overwritten internally**
    ///                    with the encoded `addOwners` call data based on `credential`.
    ///   - paymaster: Sets Paymaster configuration for the User Operation.
    ///   - estimateFeesPerGas: Prepares fee properties for the User Operation request.
    ///
    /// - Returns: The hash of the sent User Operation, or `null` if no operation was sent because the recovery address already exists.
    public func executeRecovery(
        account: SmartAccount,
        credential: WebAuthnCredential,
        partialUserOp: UserOperationV07 = UserOperationV07(),
        paymaster: Paymaster? = nil,
        estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
    ) async throws -> String? {
        if credential.publicKey.isEmpty {
            throw BaseError(shortMessage: "WebAuthn credential has missing public key")
        }

        let pubKey = WebAuthnCircleSmartAccountDelegate.extractXYFromCOSE(credential.publicKey)
        if pubKey.0.isZero, pubKey.1.isZero {
            throw BaseError(shortMessage: "WebAuthn credential has invalid public key")
        }

        logger.bundler.debug("Executing account recovery for \(account.getAddress()) for account \(account.getAddress()) with new credential")

        // Step 1: Create a mapping between the MSCA address and the WebAuthn credential */
        let owners: [AddressMappingOwner] = [
            WebAuthnAddressMappingOwner(
                WebAuthnIdentifier(
                    publicKeyX: pubKey.0.description,
                    publicKeyY: pubKey.1.description
                )
            )
        ]

        do {
            _ = try await createAddressMapping(walletAddress: account.getAddress(), owners: owners)
            logger.bundler.debug("Off-chain address mapping created successfully")
        } catch let error as InvalidParamsRpcError {
             /// Ignore "address mapping already exists" errors to ensure idempotency and allow safe retries.
             /// This prevents inconsistent states between RPC calls and onchain transactions.
            if !ErrorUtils.isMappedError(error) {
                throw BaseError(
                    shortMessage: "Failed to register the recovery address. Please try again.",
                    args: BaseErrorParameters(cause: error)
                )
            }
        }

        // Step 2: Encode the function call for the userOp */
        let addOwnersData = try Utils.getAddOwnersData(credential: credential)

        // Step 3: Send user operation to store the recovery address onchain */
        do {
            let updatedUserOp = partialUserOp
            updatedUserOp.callData = addOwnersData

            return try await sendUserOperation(
                account: account,
                calls: nil, // Set to nil since callData is assigned directly.
                partialUserOp: updatedUserOp,
                paymaster: paymaster,
                estimateFeesPerGas: estimateFeesPerGas
            )
        } catch let error as UserOperationExecutionError {
            if error.details == ExecutionRevertedError.message {
                let isOwner = try await Utils.isOwnerOf(
                    transport: transport,
                    account: account.getAddress(),
                    xOfOwnerToCheck: pubKey.0,
                    yOfOwnerToCheck: pubKey.1
                )
                if isOwner {
                    return nil
                }
            }
            throw error
        }
    }

    /// Gets the gas price options for a user operation with optional SDK version parameter.
    ///
    /// - Note: This feature is only available in Circle Buidl Wallets service.
    ///
    /// - Returns: The gas price options with low, medium, high tiers and optional verificationGasLimit.
    public func getUserOperationGasPrice() async throws -> GetUserOperationGasPriceResult {
        guard let bundlerTransport = transport as? ModularTransport else {
            throw BaseError(shortMessage: "The property transport is not the ModularTransport")
        }

        return try await bundlerTransport.getUserOperationGasPrice(
            transport: bundlerTransport
        )
    }
}
