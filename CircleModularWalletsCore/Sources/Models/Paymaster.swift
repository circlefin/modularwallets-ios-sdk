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

/// Class for setting User Operation Paymaster configuration.
///
/// If `paymaster` is `True`, it will be assumed that the Bundler Client also supports Paymaster RPC methods
/// (e.g., `pm_getPaymasterData`), and these methods will be used for sponsorship.
/// If `paymaster` is `Client`, it will use the provided Paymaster Client for sponsorship.
public class Paymaster {

    /// Represents a Paymaster configuration where the Bundler Client supports Paymaster RPC methods.
    public class True: Paymaster {

        /// Optional context for the paymaster.
        public let paymasterContext: [String: AnyEncodable]?

        /// Initializes a new `True` Paymaster configuration.
        ///
        /// - Parameters:
        ///   - paymasterContext: Optional context for the paymaster. Defaults to `nil`.
        public init(paymasterContext: [String: AnyEncodable]? = nil) {
            self.paymasterContext = paymasterContext
        }
    }

    /// Represents a Paymaster configuration using a provided Paymaster Client for sponsorship.
    public class Client: Paymaster {

        /// The Paymaster Client used for sponsorship.
        public let client: PaymasterClient

        /// Optional context for the paymaster.
        public let paymasterContext: [String: AnyEncodable]?

        /// Initializes a new `Client` Paymaster configuration.
        ///
        /// - Parameters:
        ///   - client: The Paymaster Client used for sponsorship.
        ///   - paymasterContext: Optional context for the paymaster. Defaults to `nil`.
        public init(client: PaymasterClient, paymasterContext: [String: AnyEncodable]? = nil) {
            self.client = client
            self.paymasterContext = paymasterContext
        }
    }
}
