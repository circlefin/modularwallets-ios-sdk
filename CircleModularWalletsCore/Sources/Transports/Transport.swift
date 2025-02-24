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

/// The intermediary layer that is responsible for executing outgoing requests (ie. RPC requests).
public protocol Transport {

    /// Sends an RPC request and returns the response.
    ///
    /// - Parameters:
    ///   - rpcRequest: The RPC request to be sent.
    ///
    /// - Returns: The response from the RPC request.
    ///
    /// - Throws: An error if the request fails.
    func request<P: Encodable, R: Decodable>(_ rpcRequest: RpcRequest<P>) async throws -> RpcResponse<R>
}
