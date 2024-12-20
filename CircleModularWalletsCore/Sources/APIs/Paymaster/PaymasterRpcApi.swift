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

protocol PaymasterRpcApi {

    func getPaymasterData<T: UserOperation>(
        transport: Transport,
        userOp: T,
        entryPoint: EntryPoint,
        chainId: Int,
        context: [String: AnyEncodable]?
    ) async throws -> GetPaymasterDataResult

    func getPaymasterStubData<T: UserOperation>(
        transport: Transport,
        userOp: T,
        entryPoint: EntryPoint,
        chainId: Int,
        context: [String: AnyEncodable]?
    ) async throws -> GetPaymasterStubDataResult
}

extension PaymasterRpcApi {

    func getPaymasterData<T: UserOperation>(
        transport: Transport,
        userOp: T,
        entryPoint: EntryPoint,
        chainId: Int,
        context: [String: AnyEncodable]? = nil
    ) async throws -> GetPaymasterDataResult {
        let userOp = userOp.copy()
        if userOp.callGasLimit == nil {
            userOp.callGasLimit = .zero
        }
        if userOp.verificationGasLimit == nil {
            userOp.verificationGasLimit = .zero
        }
        if userOp.preVerificationGas == nil {
            userOp.preVerificationGas = .zero
        }

        let chainIdHexStr = HexUtils.intToHex(chainId)
        var params = [AnyEncodable(userOp),
                      AnyEncodable(entryPoint.address),
                      AnyEncodable(chainIdHexStr)]
        if let context {
            params.append(AnyEncodable(context))
        }
        let req = RpcRequest(method: "pm_getPaymasterData", params: params)
        let response = try await transport.request(req) as RpcResponse<GetPaymasterDataResult>
        return response.result
    }

    func getPaymasterStubData<T: UserOperation>(
        transport: Transport,
        userOp: T,
        entryPoint: EntryPoint,
        chainId: Int,
        context: [String: AnyEncodable]? = nil
    ) async throws -> GetPaymasterStubDataResult {
        let userOp = userOp.copy()
        if userOp.callGasLimit == nil {
            userOp.callGasLimit = .zero
        }
        if userOp.verificationGasLimit == nil {
            userOp.verificationGasLimit = .zero
        }
        if userOp.preVerificationGas == nil {
            userOp.preVerificationGas = .zero
        }

        let chainIdHexStr = HexUtils.intToHex(chainId)
        var params = [AnyEncodable(userOp),
                      AnyEncodable(entryPoint.address),
                      AnyEncodable(chainIdHexStr)]
        if let context {
            params.append(AnyEncodable(context))
        }
        let req = RpcRequest(method: "pm_getPaymasterStubData", params: params)
        let response = try await transport.request(req) as RpcResponse<GetPaymasterStubDataResult>
        return response.result
    }
}
