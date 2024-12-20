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

public struct CreateWalletRequest: Encodable {
    let scaConfiguration: ScaConfiguration
    let metadata: Metadata
}

public struct CreateWalletResponse: Decodable {
    var data: Data

    struct Data: Codable {
        var wallets: [Wallet]
    }
}

public struct Wallet: Codable {
    var id: String?
    var address: String?
    var blockchain: String?
    var state: String?
    var name: String?
    var scaCore: String?
    var scaConfiguration: ScaConfiguration?
    var createDate: String?
    var updateDate: String?

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
