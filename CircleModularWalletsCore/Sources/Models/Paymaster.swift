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

public class Paymaster {

    public class True: Paymaster {
        public let paymasterContext: [String: AnyEncodable]?

        public init(paymasterContext: [String : AnyEncodable]? = nil) {
            self.paymasterContext = paymasterContext
        }
    }

    public class Client: Paymaster {
        public let client: PaymasterClient
        public let paymasterContext: [String: AnyEncodable]?

        public init(client: PaymasterClient, paymasterContext: [String : AnyEncodable]? = nil) {
            self.client = client
            self.paymasterContext = paymasterContext
        }
    }
}
