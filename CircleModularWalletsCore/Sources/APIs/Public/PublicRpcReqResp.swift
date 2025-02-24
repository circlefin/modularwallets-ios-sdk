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

struct EthCallParams: Encodable {
    let from: String?
    let to: String
    let data: String
    let block: String

    enum TransactionCodingKeys: String, CodingKey {
        case from
        case to
        case data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        var nested = container.nestedContainer(keyedBy: TransactionCodingKeys.self)
        if let from = from {
            try nested.encode(from, forKey: .from)
        }
        try nested.encode(to, forKey: .to)
        try nested.encode(data, forKey: .data)
        try container.encode(block)
    }
}

/// Response model for estimating fees per gas.
/// Result for ``PublicRpcApi/estimateFeesPerGas(transport:feeValuesType:)``
public struct EstimateFeesPerGasResult: Encodable {

    /// Total fee per gas in wei (gasPrice/baseFeePerGas + maxPriorityFeePerGas).
    public let maxFeePerGas: BigInt? // eip1559

    /// Max priority fee per gas (in wei).
    public let maxPriorityFeePerGas: BigInt? // eip1559

    /// Legacy gas price (optional, usually undefined for EIP-1559).
    public let gasPrice: BigInt? // legacy

    init(maxFeePerGas: BigInt?, maxPriorityFeePerGas: BigInt?, gasPrice: BigInt? = nil) {
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.gasPrice = gasPrice
    }

    enum CodingKeys: CodingKey {
        case maxFeePerGas
        case maxPriorityFeePerGas
        case gasPrice
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeBigInt(self.maxFeePerGas, forKey: .maxFeePerGas)
        try container.encodeBigInt(self.maxPriorityFeePerGas, forKey: .maxPriorityFeePerGas)
        try container.encodeBigInt(self.gasPrice, forKey: .gasPrice)
    }
}
