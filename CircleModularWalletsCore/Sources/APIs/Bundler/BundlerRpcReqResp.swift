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
import BigInt

/// Result for ``BundlerClient/estimateUserOperationGas(userOp:entryPoint:)``
public struct EstimateUserOperationGasResult: Codable {
    let preVerificationGas: BigInt?
    let verificationGasLimit: BigInt?
    let callGasLimit: BigInt?
    let paymasterVerificationGasLimit: BigInt?
    let paymasterPostOpGasLimit: BigInt?

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

/// Result for ``BundlerClient/getUserOperation(userOpHash:)``
public struct GetUserOperationResult: Codable {
    let blockHash: String?
    let blockNumber: BigInt?
    let transactionHash: String?
    let entryPoint: String?
    let userOperation: UserOperationType?

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

/// Result for ``BundlerClient/getUserOperationReceipt(userOpHash:)``
public struct GetUserOperationReceiptResult: Codable {
    public let userOpHash: String?
    public let sender: String?
    public let nonce: BigInt?
    public let actualGasCost: BigInt?
    public let actualGasUsed: BigInt?
    public let success: Bool?
    public let paymaster: String?
    public let logs: [Log]?
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
    
    // https://github.com/wevm/viem/blob/e7431e88b0e8b83719c91f5a6a57da1a10076a1c/src/account-abstraction/types/userOperation.ts#L167
    public struct UserOperationReceipt: Codable {
        let transactionHash: String?
        let transactionIndex: String?
        let blockHash: String?
        let blockNumber: String?
        let from: String?
        let to: String?
        let cumulativeGasUsed: String?
        let gasUsed: String?
        let logs: [Log]?
        let logsBloom: String?
        let status: String?
        let effectiveGasPrice: String?
    }

    // https://github.com/wevm/viem/blob/e7431e88b0e8b83719c91f5a6a57da1a10076a1c/src/types/log.ts#L15
    public struct Log: Codable {
        let removed: Bool?
        let logIndex: String?
        let transactionIndex: String?
        let transactionHash: String?
        let blockHash: String?
        let blockNumber: String?
        let address: String?
        let data: String?
        let topics: [String]?
    }
}
