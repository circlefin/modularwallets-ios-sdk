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

/// A Client provides access to a subset of Actions.
/// There are two types of Clients in CircleModularWalletsCore: ``BundlerClient``, ``PaymasterClient``
public class Client: @unchecked Sendable {
    
    /// The blockchain that the client interacts with.
    public let chain: Chain

    /// The transport mechanism used for making RPC requests.
    public let transport: Transport

    /// Initialize a Client with your desired Chain (e.g. ``Mainnet``) and Transport (e.g. ``http(url:options:)``).
    ///
    /// - Properties:
    ///   - chain: The blockchain that the client interacts with.
    ///   - transport: The transport mechanism used for making RPC requests.
    public init(chain: Chain, transport: Transport) {
        self.chain = chain
        self.transport = transport
    }
}
