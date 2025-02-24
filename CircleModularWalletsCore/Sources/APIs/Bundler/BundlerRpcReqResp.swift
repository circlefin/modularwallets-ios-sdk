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

/// Response model for estimating gas usage for user operations.
/// Result for ``BundlerClient/estimateUserOperationGas(userOp:entryPoint:)``
public struct EstimateUserOperationGasResult: Codable {

    /// Gas overhead of this UserOperation.
    public let preVerificationGas: BigInt?

    /// Estimation of gas limit required by the validation of this UserOperation.
    public let verificationGasLimit: BigInt?

    /// Estimation of gas limit required by the inner account execution.
    public let callGasLimit: BigInt?

    /// Estimation of gas limit required by the paymaster verification, if the UserOperation defines a Paymaster address.
    public let paymasterVerificationGasLimit: BigInt?

    /// The amount of gas to allocate for the paymaster post-operation code.
    public let paymasterPostOpGasLimit: BigInt?

    init(preVerificationGas: BigInt?, verificationGasLimit: BigInt?, callGasLimit: BigInt?, paymasterVerificationGasLimit: BigInt?, paymasterPostOpGasLimit: BigInt?) {
        self.preVerificationGas = preVerificationGas
        self.verificationGasLimit = verificationGasLimit
        self.callGasLimit = callGasLimit
        self.paymasterVerificationGasLimit = paymasterVerificationGasLimit
        self.paymasterPostOpGasLimit = paymasterPostOpGasLimit
    }

    enum CodingKeys: CodingKey {
        case preVerificationGas
        case verificationGasLimit
        case callGasLimit
        case paymasterVerificationGasLimit
        case paymasterPostOpGasLimit
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeBigInt(self.preVerificationGas, forKey: .preVerificationGas)
        try container.encodeBigInt(self.verificationGasLimit, forKey: .verificationGasLimit)
        try container.encodeBigInt(self.callGasLimit, forKey: .callGasLimit)
        try container.encodeBigInt(self.paymasterVerificationGasLimit, forKey: .paymasterVerificationGasLimit)
        try container.encodeBigInt(self.paymasterPostOpGasLimit, forKey: .paymasterPostOpGasLimit)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.preVerificationGas = try container.decodeToBigInt(forKey: .preVerificationGas)
        self.verificationGasLimit = try container.decodeToBigInt(forKey: .verificationGasLimit)
        self.callGasLimit = try container.decodeToBigInt(forKey: .callGasLimit)
        self.paymasterVerificationGasLimit = try container.decodeToBigInt(forKey: .paymasterVerificationGasLimit)
        self.paymasterPostOpGasLimit = try container.decodeToBigInt(forKey: .paymasterPostOpGasLimit)
    }
}

/// Response model for getting user operation details.
/// Result for ``BundlerClient/getUserOperation(userOpHash:)``
public struct GetUserOperationResult: Codable {

    /// The block hash the User Operation was included on.
    public let blockHash: String?

    /// The block number the User Operation was included on.
    public let blockNumber: BigInt?

    /// The hash of the transaction which included the User Operation.
    public let transactionHash: String?

    /// The EntryPoint which handled the User Operation.
    public let entryPoint: String?

    /// The User Operation.
    public let userOperation: UserOperationType?

    enum CodingKeys: String, CodingKey {
        case userOperation
        case transactionHash
        case entryPoint
        case blockNumber
        case blockHash
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(blockHash, forKey: .blockHash)
        try container.encodeIfPresent(transactionHash, forKey: .transactionHash)
        try container.encodeIfPresent(entryPoint, forKey: .entryPoint)
        try container.encodeBigInt(blockNumber, forKey: .blockNumber)

        if case let .v07(userOp) = userOperation {
            try container.encodeIfPresent(userOp, forKey: .userOperation)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blockHash = try container.decodeIfPresent(String.self, forKey: .blockHash)
        transactionHash = try container.decodeIfPresent(String.self, forKey: .transactionHash)
        entryPoint = try container.decodeIfPresent(String.self, forKey: .entryPoint)
        blockNumber = try container.decodeToBigInt(forKey: .blockNumber)

        if let userOp = try? container.decodeIfPresent(UserOperationV07.self, forKey: .userOperation) {
            self.userOperation = .v07(userOp)
        } else {
            self.userOperation = nil
        }
    }
}

/// Data structure representing the receipt of a user operation.
/// Result for ``BundlerClient/getUserOperationReceipt(userOpHash:)``
public struct GetUserOperationReceiptResult: Codable {

    /// Hash of the user operation.
    public let userOpHash: String?

    /// Address of the sender.
    public let sender: String?

    /// Anti-replay parameter (nonce).
    public let nonce: BigInt?

    /// Actual gas cost.
    public let actualGasCost: BigInt?

    /// Actual gas used.
    public let actualGasUsed: BigInt?

    /// If the user operation execution was successful.
    public let success: Bool?

    /// Paymaster for the user operation.
    public let paymaster: String?

    /// Logs emitted during execution.
    public let logs: [Log]?

    /// Transaction receipt of the user operation execution.
    public let receipt: UserOperationReceipt

    enum CodingKeys: CodingKey {
        case userOpHash
        case sender
        case nonce
        case actualGasCost
        case actualGasUsed
        case success
        case paymaster
        case logs
        case receipt
    }

    public func encodeIfPresent(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.userOpHash, forKey: .userOpHash)
        try container.encodeIfPresent(self.sender, forKey: .sender)
        try container.encodeBigInt(self.nonce, forKey: .nonce)
        try container.encodeBigInt(self.actualGasCost, forKey: .actualGasCost)
        try container.encodeBigInt(self.actualGasUsed, forKey: .actualGasUsed)
        try container.encodeIfPresent(self.success, forKey: .success)
        try container.encodeIfPresent(self.paymaster, forKey: .paymaster)
        try container.encodeIfPresent(self.logs, forKey: .logs)
        try container.encode(self.receipt, forKey: .receipt)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userOpHash = try container.decodeIfPresent(String.self, forKey: .userOpHash)
        self.sender = try container.decodeIfPresent(String.self, forKey: .sender)
        self.nonce = try container.decodeToBigInt(forKey: .nonce)
        self.actualGasCost = try container.decodeToBigInt(forKey: .actualGasCost)
        self.actualGasUsed = try container.decodeToBigInt(forKey: .actualGasUsed)
        self.success = try container.decodeIfPresent(Bool.self, forKey: .success)
        self.paymaster = try container.decodeIfPresent(String.self, forKey: .paymaster)
        self.logs = try container.decodeIfPresent([GetUserOperationReceiptResult.Log].self, forKey: .logs)
        self.receipt = try container.decode(GetUserOperationReceiptResult.UserOperationReceipt.self, forKey: .receipt)
    }
    
    /// Data structure representing the receipt of a transaction.
    // https://github.com/wevm/viem/blob/e7431e88b0e8b83719c91f5a6a57da1a10076a1c/src/account-abstraction/types/userOperation.ts#L167
    public struct UserOperationReceipt: Codable {

        /// Hash of this transaction.
        public let transactionHash: String?

        /// Index of this transaction in the block.
        public let transactionIndex: String?

        /// Hash of the block containing this transaction.
        public let blockHash: String?

        /// Number of the block containing this transaction.
        public let blockNumber: String?

        /// Transaction sender.
        public let from: String?

        /// Transaction recipient or `nil` if deploying a contract.
        public let to: String?

        /// Gas used by this and all preceding transactions in this block.
        public let cumulativeGasUsed: String?

        /// Gas used by this transaction.
        public let gasUsed: String?

        /// List of log objects generated by this transaction.
        public let logs: [Log]?

        /// Logs bloom filter.
        public let logsBloom: String?

        /// `success` if this transaction was successful or `reverted` if it failed.
        public let status: String?

        /// Pre-London, it is equal to the transaction's gasPrice. Post-London, it is equal to the actual gas price paid for inclusion.
        public let effectiveGasPrice: String?
    }

    /// Data structure representing a log entry.
    // https://github.com/wevm/viem/blob/e7431e88b0e8b83719c91f5a6a57da1a10076a1c/src/types/log.ts#L15
    public struct Log: Codable {

        /// `true` if this filter has been destroyed and is invalid.
        public let removed: Bool?

        /// Index of this log within its block or `nil` if pending.
        public let logIndex: String?

        /// Index of the transaction that created this log or `nil` if pending.
        public let transactionIndex: String?

        /// Hash of the transaction that created this log or `nil` if pending.
        public let transactionHash: String?

        /// Hash of the block containing this log or `nil` if pending.
        public let blockHash: String?

        /// Number of the block containing this log or `nil` if pending.
        public let blockNumber: String?

        /// The address from which this log originated.
        public let address: String?

        /// Contains the non-indexed arguments of the log.
        public let data: String?

        /// List of topics associated with this log.
        public let topics: [String]?
    }
}
