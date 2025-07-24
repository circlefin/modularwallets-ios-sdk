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
import web3swift
import Web3Core
import BigInt

class LocalCircleSmartAccountDelegate: CircleSmartAccountDelegate {

    static var WALLET_PREFIX: String { "wallet" }
    
    private let owner: LocalAccount

    init(_ owner: LocalAccount) {
        self.owner = owner
    }

    func getModularWalletAddress(
        transport: ModularTransport,
        version: String,
        name: String?
    ) async throws -> ModularWallet {
        return try await getModularWalletAddress(
            transport: transport,
            address: owner.getAddress(),
            version: version,
            name: name
        )
    }

    func signAndWrap(
        hash: String,
        hasUserOpGas: Bool
    ) async throws -> String {
        let signature = hasUserOpGas ?
        try await owner.sign(messageHash: Utils.hashMessage(hex: hash)) :
        try await owner.sign(messageHash: hash)

        let signatureData = try Utils.deserializeSignature(signature)
        let encodePacked = encodePackedForSignature(
            signatureData: signatureData,
            hasUserOpGas: hasUserOpGas
        )

        return encodePacked
    }
}

extension LocalCircleSmartAccountDelegate {

    // MARK: Internal Usage

    func getModularWalletAddress(
        transport: ModularTransport,
        address: String,
        version: String,
        name: String? = nil
    ) async throws -> ModularWallet {
        let request = GetAddressReq(
            scaConfiguration: ScaConfiguration(
                initialOwnershipConfiguration: .init(
                    ownershipContractAddress: nil,
                    weightedMultiSig: .init(
                        owners: [.init(address: address,
                                       weight: OWNER_WEIGHT)],
                        webauthnOwners: nil,
                        thresholdWeight: THRESHOLD_WEIGHT)
                ),
                scaCore: version,
                initCode: nil),
            metadata: .init(name: name)
        )
        let wallet = try await transport.getAddress(
            transport: transport,
            req: request
        )
        return wallet
    }

    /// Wraps a raw Secp256k1 signature into the ABI-encoded format expected by smart contract.
    func encodePackedForSignature(
        signatureData: SECP256K1.UnmarshaledSignature,
        hasUserOpGas: Bool
    ) -> String {
        let sigType: UInt8
        if hasUserOpGas {
            sigType = signatureData.v + SIG_TYPE_FLAG_DIGEST
        } else {
            sigType = signatureData.v
        }

        let encoded = Utils.encodePacked([
            signatureData.r.map { $0 },
            signatureData.s.map { $0 },
            sigType
        ]).addHexPrefix()

        return encoded
    }
}
