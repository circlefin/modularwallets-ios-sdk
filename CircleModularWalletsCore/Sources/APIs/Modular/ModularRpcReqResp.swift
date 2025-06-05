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

struct GetAddressReq: Encodable {
    let scaConfiguration: ScaConfiguration
    let metadata: Metadata
}

/// Represents the Circle modular wallet.
struct ModularWallet: Codable, Sendable {

    /// The wallet id.
    var id: String?

    /// The wallet address.
    var address: String?

    /// The blockchain.
    var blockchain: String?

    /// The state.
    var state: String?

    /// The name of the wallet.
    var name: String?

    /// The SCA core.
    var scaCore: String?

    /// The SCA configuration.
    var scaConfiguration: ScaConfiguration?

    /// The create date.
    var createDate: String?

    /// The last update date.
    var updateDate: String?

    /// Gets the initialization code from the SCA configuration.
    ///
    /// - Returns: The initialization code if present, `nil` otherwise.
    func getInitCode() -> String? {
        return scaConfiguration?.initCode
    }
}

struct ScaConfiguration: Codable {
    let initialOwnershipConfiguration: InitialOwnershipConfiguration
    let scaCore: String?
    let initCode: String?

    struct InitialOwnershipConfiguration: Codable {
        let ownershipContractAddress: String?
        let weightedMultiSig: WeightedMultiSig?

        enum CodingKeys: String, CodingKey {
            case ownershipContractAddress
            case weightedMultiSig = "weightedMultisig"
        }

        struct WeightedMultiSig: Codable {
            let owners: [Owner]?
            let webauthnOwners: [WebAuthnOwner]?
            let thresholdWeight: Int?

            struct Owner: Codable {
                let address: String
                let weight: Int
            }

            struct WebAuthnOwner: Codable {
                let publicKeyX: String
                let publicKeyY: String
                let weight: Int
            }
        }
    }
}

struct Metadata: Codable {
    let name: String?
}

struct CreateAddressMappingReq: Encodable {
    let walletAddress: String
    let owners: [AddressMappingOwner]
}

/// Represents the response from the circle_getUserOperationGasPrice RPC method.
/// This structure provides different gas price options (low, medium, high) for
/// user operations along with verification gas limits for both
/// deployed and non-deployed smart accounts.
public struct GetUserOperationGasPriceResult: Decodable {

    /// The low-priority, medium-priority and high-priority gas price option.
    public let low, medium, high: GasPriceOption

    /// The optional deployed verification gas.
    public let deployed: BigInt?
    
    /// The optional non-deployed verification gas.
    public let notDeployed: BigInt?

    enum CodingKeys: CodingKey {
        case low, medium, high
        case verificationGasLimit
        case deployed
        case notDeployed
    }

    init(low: GasPriceOption,
         medium: GasPriceOption,
         high: GasPriceOption,
         deployed: BigInt? = nil,
         notDeployed: BigInt? = nil) {
        self.low = low
        self.medium = medium
        self.high = high
        self.deployed = deployed
        self.notDeployed = notDeployed
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.low = try container.decode(GasPriceOption.self, forKey: .low)
        self.medium = try container.decode(GasPriceOption.self, forKey: .medium)
        self.high = try container.decode(GasPriceOption.self, forKey: .high)
        self.deployed = try container.decodeToBigInt(forKey: .deployed, isHex: false)
        self.notDeployed = try container.decodeToBigInt(forKey: .notDeployed, isHex: false)
    }
}

/// Represents a gas price option.
/// Contains the maximum fee per gas and maximum priority fee per gas for
/// a specific priority level (low, medium, or high).
public struct GasPriceOption: Decodable {

    /// The maximum fee per gas.
    public let maxFeePerGas: BigInt

    /// The maximum priority fee per gas.
    public let maxPriorityFeePerGas: BigInt

    enum CodingKeys: CodingKey {
        case maxFeePerGas
        case maxPriorityFeePerGas
    }

    init(maxFeePerGas: BigInt, maxPriorityFeePerGas: BigInt) {
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.maxFeePerGas = try container.decodeToBigInt(forKey: .maxFeePerGas, isHex: false) ?? .zero
        self.maxPriorityFeePerGas = try container.decodeToBigInt(forKey: .maxPriorityFeePerGas, isHex: false) ?? .zero
    }
}
