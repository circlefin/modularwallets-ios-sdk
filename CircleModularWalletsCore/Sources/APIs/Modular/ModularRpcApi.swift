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

protocol ModularRpcApi {
    
    func circleGetAddress(
        transport: Transport,
        req: CreateWalletRequest
    ) async throws -> Wallet
}

extension ModularRpcApi {

    func circleGetAddress(
        transport: Transport,
        req: CreateWalletRequest
    ) async throws -> Wallet {
        let req = RpcRequest(method: "circle_getAddress", params: [req])
        let response = try await transport.request(req) as RpcResponse<Wallet>
        return response.result
    }
}
