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

struct EmptyParam: Encodable {}
let emptyParams = [EmptyParam]()

/// Data structure for RPC request
public struct RpcRequest<P: Encodable>: Encodable {
    let id: Int = Int(Date().timeIntervalSince1970 * 1000)
    let jsonrpc: String = "2.0"
    let method: String
    let params: P?
}

/// Data structure for RPC response
public struct RpcResponse<R: Decodable>: Decodable {
    let id: Int
    let jsonrpc: String
    let result: R
}
