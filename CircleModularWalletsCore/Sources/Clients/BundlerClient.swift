//
// Copyright (c) 2024, Circle Internet Group, Inc. All rights reserved.
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

public class BundlerClient: Client, BundlerRpcApi, PublicRpcApi {

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

    public func getChainId() async throws -> Int {
        try await self.getChainId(transport: transport)
    }

    public func getSupportedEntryPoints() async throws -> [String] {
        try await self.getSupportedEntryPoints(transport: transport)
    }

    public func getUserOperation(userOpHash: String) async throws -> GetUserOperationResult {
        try await self.getUserOperation(transport: transport, userOpHash: userOpHash)
    }

    public func getUserOperationReceipt(userOpHash: String) async throws -> GetUserOperationReceiptResult {
        try await self.getUserOperationReceipt(transport: transport, userOpHash: userOpHash)
    }

    public func prepareUserOperation(
        account: SmartAccount,
        calls: [EncodeCallDataArg]?,
        partialUserOp: UserOperationV07,
        paymaster: Paymaster? = nil,
        estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
    ) async throws -> UserOperationV07 {
        try await self.prepareUserOperation(transport: transport, account: account, calls: calls, partialUserOp: partialUserOp, paymaster: paymaster, bundlerClient: self, estimateFeesPerGas: estimateFeesPerGas)
    }

    public func sendUserOperation(
        account: SmartAccount,
        calls: [EncodeCallDataArg]?,
        partialUserOp: UserOperationV07 = .init(),
        paymaster: Paymaster? = nil,
        estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)? = nil
    ) async throws -> String? {
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

    public func waitForUserOperationReceipt(
        userOpHash: String,
        pollingInterval: Int = 4000,
        retryCount: Int = 6,
        timeout: Int? = nil
    ) async throws -> GetUserOperationReceiptResult {
        try await self.waitForUserOperationReceipt(transport: transport, userOpHash: userOpHash, pollingInterval: pollingInterval, retryCount: retryCount, timeout: timeout)
    }

    public func getBalance(
        address: String,
        blockNumber: BlockNumber = .latest
    ) async throws -> BigInt {
        let result = try await getBalance(transport: transport,
                                          address: address,
                                          blockNumber: blockNumber)
        return result
    }

    public func getBlockNumber() async throws -> BigInt {
        let result = try await getBlockNum(transport: transport)
        return result
    }

    public func getGasPrice() async throws-> BigInt {
        let result = try await getGasPrice(transport: transport)
        return result
    }

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

    public func getCode(
        address: String,
        blockNumber: BlockNumber = .latest
    ) async throws -> String {
        return try await getCode(transport: transport,
                                 address: address,
                                 blockNumber: blockNumber)
    }

    public func estimateMaxPriorityFeePerGas() async throws -> BigInt {
        return try await getMaxPriorityFeePerGas(transport: transport)
    }

    public func getBlock(
        includeTransactions: Bool = false,
        blockNumber: BlockNumber = .latest
    ) async throws -> Block {
        return try await getBlock(transport: transport,
                                  includeTransactions: includeTransactions,
                                  blockNumber: blockNumber)
    }
}
