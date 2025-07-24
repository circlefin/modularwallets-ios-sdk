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

protocol ModularRpcApi {

    func getAddress(transport: Transport, req: GetAddressReq) async throws -> ModularWallet

    func createAddressMapping(
        transport: Transport,
        walletAddress: String,
        owners: [AddressMappingOwner]
    ) async throws -> [AddressMappingResult]

    func getAddressMapping(
        transport: Transport,
        owner: AddressMappingOwner
    ) async throws -> [AddressMappingResult]

    func getUserOperationGasPrice(
        transport: Transport
    ) async throws -> GetUserOperationGasPriceResult
}

extension ModularRpcApi {

    func getAddress(transport: Transport, req: GetAddressReq) async throws -> ModularWallet {
        let req = RpcRequest(method: "circle_getAddress", params: [req])
        let response = try await transport.request(req) as RpcResponse<ModularWallet>
        return response.result
    }

    func createAddressMapping(
        transport: Transport,
        walletAddress: String,
        owners: [AddressMappingOwner]
    ) async throws -> [AddressMappingResult] {
        if !Utils.isAddress(walletAddress) {
            throw BaseError(shortMessage: "walletAddress is invalid")
        }

        if owners.isEmpty {
            throw BaseError(shortMessage: "At least one owner must be provided")
        }

        for (index, owner) in owners.enumerated() {
            switch owner {
            case let eoaOwner as EoaAddressMappingOwner:
                if !Utils.isAddress(eoaOwner.identifier.address) {
                    throw BaseError(shortMessage: "EOA owner at index \(index) has an invalid address")
                }

            case let webAuthnOwner as WebAuthnAddressMappingOwner:
                if webAuthnOwner.identifier.publicKeyX.isEmpty || webAuthnOwner.identifier.publicKeyY.isEmpty {
                    throw BaseError(shortMessage: "Webauthn owner at index \(index) must have publicKeyX and publicKeyY")
                }

            default:
                throw BaseError(shortMessage: "Owner at index \(index) has an invalid type")
            }
        }

        let req = RpcRequest(
            method: "circle_createAddressMapping",
            params: [CreateAddressMappingReq(walletAddress: walletAddress, owners: owners)]
        )

        let response = try await transport.request(req) as RpcResponse<[AddressMappingResult]>
        return response.result
    }

    func getAddressMapping(
        transport: Transport,
        owner: AddressMappingOwner
    ) async throws -> [AddressMappingResult] {
        let req = RpcRequest(
            method: "circle_getAddressMapping",
            params: [GetAddressMappingReq(owner: owner)]
        )

        let response = try await transport.request(req) as RpcResponse<[AddressMappingResult]>
        return response.result
    }

    func getUserOperationGasPrice(
        transport: Transport
    ) async throws -> GetUserOperationGasPriceResult {
        let params = [AnyEncodable]()
        let req = RpcRequest(method: "circle_getUserOperationGasPrice", params: params)
        let response = try await transport.request(req) as RpcResponse<GetUserOperationGasPriceResult>
        return response.result
    }
}
