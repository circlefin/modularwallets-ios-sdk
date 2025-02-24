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

/// Data class representing a user operation for version 0.7.
public class UserOperationV07: UserOperation {

    /// The address of the sender.
    public var sender: String?

    /// The nonce of the operation.
    public var nonce: BigInt?

    /// The data to be sent in the call.
    public var callData: String?

    /// The gas limit for the call.
    public var callGasLimit: BigInt?

    /// The gas limit for verification.
    public var verificationGasLimit: BigInt?

    /// The gas used before verification.
    public var preVerificationGas: BigInt?

    /// The maximum priority fee per gas.
    public var maxPriorityFeePerGas: BigInt?

    /// The maximum fee per gas.
    public var maxFeePerGas: BigInt?

    /// The signature of the operation.
    public var signature: String?

    /// The factory address.
    public var factory: String?

    /// The data for the factory.
    public var factoryData: String?

    /// The paymaster address.
    public var paymaster: String?

    /// The gas limit for paymaster verification.
    public var paymasterVerificationGasLimit: BigInt?

    /// The gas limit for paymaster post-operation.
    public var paymasterPostOpGasLimit: BigInt?

    /// The data for the paymaster.
    public var paymasterData: String?

    public init(sender: String? = nil, nonce: BigInt? = nil, callData: String? = nil, callGasLimit: BigInt? = nil, verificationGasLimit: BigInt? = nil, preVerificationGas: BigInt? = nil, maxPriorityFeePerGas: BigInt? = nil, maxFeePerGas: BigInt? = nil, signature: String? = nil, factory: String? = nil, factoryData: String? = nil, paymaster: String? = nil, paymasterVerificationGasLimit: BigInt? = nil, paymasterPostOpGasLimit: BigInt? = nil, paymasterData: String? = nil) {
        self.sender = sender
        self.nonce = nonce
        self.callData = callData
        self.callGasLimit = callGasLimit
        self.verificationGasLimit = verificationGasLimit
        self.preVerificationGas = preVerificationGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.maxFeePerGas = maxFeePerGas
        self.signature = signature
        self.factory = factory
        self.factoryData = factoryData
        self.paymaster = paymaster
        self.paymasterVerificationGasLimit = paymasterVerificationGasLimit
        self.paymasterPostOpGasLimit = paymasterPostOpGasLimit
        self.paymasterData = paymasterData
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return UserOperationV07(
            sender: self.sender,
            nonce: self.nonce,
            callData: self.callData,
            callGasLimit: self.callGasLimit,
            verificationGasLimit: self.verificationGasLimit,
            preVerificationGas: self.preVerificationGas,
            maxPriorityFeePerGas: self.maxPriorityFeePerGas,
            maxFeePerGas: self.maxFeePerGas,
            signature: self.signature,
            factory: self.factory,
            factoryData: self.factoryData,
            paymaster: self.paymaster,
            paymasterVerificationGasLimit: self.paymasterVerificationGasLimit,
            paymasterPostOpGasLimit: self.paymasterPostOpGasLimit,
            paymasterData: self.paymasterData
        )
    }

    public func copy() -> Self {
        // swiftlint:disable:next force_cast
        return self.copy(with: nil) as! Self
    }

    enum CodingKeys: CodingKey {
        case sender
        case nonce
        case callData
        case callGasLimit
        case verificationGasLimit
        case preVerificationGas
        case maxPriorityFeePerGas
        case maxFeePerGas
        case signature
        case factory
        case factoryData
        case paymaster
        case paymasterVerificationGasLimit
        case paymasterPostOpGasLimit
        case paymasterData
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.sender, forKey: .sender)
        try container.encodeBigInt(self.nonce, forKey: .nonce)
        try container.encodeIfPresent(self.callData, forKey: .callData)
        try container.encodeBigInt(self.callGasLimit, forKey: .callGasLimit)
        try container.encodeBigInt(self.verificationGasLimit, forKey: .verificationGasLimit)
        try container.encodeBigInt(self.preVerificationGas, forKey: .preVerificationGas)
        try container.encodeBigInt(self.maxPriorityFeePerGas, forKey: .maxPriorityFeePerGas)
        try container.encodeBigInt(self.maxFeePerGas, forKey: .maxFeePerGas)
        try container.encodeIfPresent(self.signature, forKey: .signature)
        try container.encodeIfPresent(self.factory, forKey: .factory)
        try container.encodeIfPresent(self.factoryData, forKey: .factoryData)
        try container.encodeIfPresent(self.paymaster, forKey: .paymaster)
        try container.encodeBigInt(self.paymasterVerificationGasLimit, forKey: .paymasterVerificationGasLimit)
        try container.encodeBigInt(self.paymasterPostOpGasLimit, forKey: .paymasterPostOpGasLimit)
        try container.encodeIfPresent(self.paymasterData, forKey: .paymasterData)
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sender = try container.decodeIfPresent(String.self, forKey: .sender)
        self.nonce = try container.decodeToBigInt(forKey: .nonce)
        self.callData = try container.decodeIfPresent(String.self, forKey: .callData)
        self.callGasLimit = try container.decodeToBigInt(forKey: .callGasLimit)
        self.verificationGasLimit = try container.decodeToBigInt(forKey: .verificationGasLimit)
        self.preVerificationGas = try container.decodeToBigInt(forKey: .preVerificationGas)
        self.maxPriorityFeePerGas = try container.decodeToBigInt(forKey: .maxPriorityFeePerGas)
        self.maxFeePerGas = try container.decodeToBigInt(forKey: .maxFeePerGas)
        self.signature = try container.decodeIfPresent(String.self, forKey: .signature)
        self.factory = try container.decodeIfPresent(String.self, forKey: .factory)
        self.factoryData = try container.decodeIfPresent(String.self, forKey: .factoryData)
        self.paymaster = try container.decodeIfPresent(String.self, forKey: .paymaster)
        self.paymasterVerificationGasLimit = try container.decodeToBigInt(forKey: .paymasterVerificationGasLimit)
        self.paymasterPostOpGasLimit = try container.decodeToBigInt(forKey: .paymasterPostOpGasLimit)
        self.paymasterData = try container.decodeIfPresent(String.self, forKey: .paymasterData)
    }

}
