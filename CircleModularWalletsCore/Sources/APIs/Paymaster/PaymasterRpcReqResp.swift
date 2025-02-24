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

/// Data structure representing the result of getting paymaster data.
public struct GetPaymasterDataResult: Codable {

    /// Paymaster address (entrypoint v0.7).
    public let paymaster: String?

    /// Paymaster data (entrypoint v0.7).
    public let paymasterData: String?

    /// Combined paymaster and data (entrypoint v0.6).
    public let paymasterAndData: String?

    /// Gas limit for post-operation of paymaster (entrypoint v0.7).
    public let paymasterPostOpGasLimit: BigInt?

    /// Gas limit for verification of paymaster (entrypoint v0.7).
    public let paymasterVerificationGasLimit: BigInt?

    enum CodingKeys: CodingKey {
        case paymaster
        case paymasterData
        case paymasterPostOpGasLimit
        case paymasterVerificationGasLimit
        case paymasterAndData
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.paymaster, forKey: .paymaster)
        try container.encodeIfPresent(self.paymasterData, forKey: .paymasterData)
        try container.encodeBigInt(self.paymasterPostOpGasLimit, forKey: .paymasterPostOpGasLimit)
        try container.encodeBigInt(self.paymasterVerificationGasLimit, forKey: .paymasterVerificationGasLimit)
        try container.encodeIfPresent(self.paymasterAndData, forKey: .paymasterAndData)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.paymaster = try container.decodeIfPresent(String.self, forKey: .paymaster)
        self.paymasterData = try container.decodeIfPresent(String.self, forKey: .paymasterData)
        self.paymasterPostOpGasLimit = try container.decodeToBigInt(forKey: .paymasterPostOpGasLimit)
        self.paymasterVerificationGasLimit = try container.decodeToBigInt(forKey: .paymasterVerificationGasLimit)
        self.paymasterAndData = try container.decodeIfPresent(String.self, forKey: .paymasterAndData)
    }
}

/// Data structure representing the result of getting paymaster stub data.
public struct GetPaymasterStubDataResult: Codable {

    /// Paymaster address (entrypoint v0.7).
    public let paymaster: String?

    /// Paymaster data (entrypoint v0.7).
    public let paymasterData: String?

    /// Combined paymaster and data (entrypoint v0.6).
    public let paymasterAndData: String?

    /// Gas limit for post-operation of paymaster (entrypoint v0.7).
    public let paymasterPostOpGasLimit: BigInt?

    /// Gas limit for verification of paymaster (entrypoint v0.7).
    public let paymasterVerificationGasLimit: BigInt?

    /// Indicates if the caller does not need to call `pm_getPaymasterData`.
    public let isFinal: Bool?

    /// Sponsor information.
    public let sponsor: SponsorInfo?

    /// Data structure representing sponsor information.
    public struct SponsorInfo: Codable {

        /// Sponsor name.
        public let name: String

        /// Sponsor icon (optional).
        public let icon: String?
    }

    enum CodingKeys: CodingKey {
        case paymaster
        case paymasterData
        case paymasterPostOpGasLimit
        case paymasterVerificationGasLimit
        case paymasterAndData
        case isFinal
        case sponsor
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.paymaster, forKey: .paymaster)
        try container.encodeIfPresent(self.paymasterData, forKey: .paymasterData)
        try container.encodeBigInt(self.paymasterPostOpGasLimit, forKey: .paymasterPostOpGasLimit)
        try container.encodeBigInt(self.paymasterVerificationGasLimit, forKey: .paymasterVerificationGasLimit)
        try container.encodeIfPresent(self.paymasterAndData, forKey: .paymasterAndData)
        try container.encodeIfPresent(self.isFinal, forKey: .isFinal)
        try container.encodeIfPresent(self.sponsor, forKey: .sponsor)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.paymaster = try container.decodeIfPresent(String.self, forKey: .paymaster)
        self.paymasterData = try container.decodeIfPresent(String.self, forKey: .paymasterData)
        self.paymasterPostOpGasLimit = try container.decodeToBigInt(forKey: .paymasterPostOpGasLimit)
        self.paymasterVerificationGasLimit = try container.decodeToBigInt(forKey: .paymasterVerificationGasLimit)
        self.paymasterAndData = try container.decodeIfPresent(String.self, forKey: .paymasterAndData)
        self.isFinal = try container.decodeIfPresent(Bool.self, forKey: .isFinal)
        self.sponsor = try container.decodeIfPresent(GetPaymasterStubDataResult.SponsorInfo.self, forKey: .sponsor)
    }
}
