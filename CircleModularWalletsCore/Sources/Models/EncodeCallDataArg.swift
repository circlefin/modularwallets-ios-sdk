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
import BigInt

/// Data structure representing arguments required for encoding call data.
///
/// Used in `SmartAccount.encodeCalls`:
/// - `to`: Required.
/// - `value`: Optional, defaults to 0.
/// - `data`: Optional, if no data returns “0x”.
///
/// Used in `EncodeFunctionData`:
/// - `abiJson`: Required.
/// - `functionName`: Required.
/// - `args`: Optional.
public struct EncodeCallDataArg: Encodable {

    /// The recipient address.
    public let to: String

    /// The value to be sent with the transaction.
    public let value: BigInt?

    /// The call data in hexadecimal format.
    public let data: String?

    /// The ABI definition in JSON format.
    public let abiJson: String?

    /// The function name.
    public let functionName: String?

    /// The arguments for the function call.
    public let args: [AnyEncodable]?

    public init(to: String, value: BigInt? = nil,
                data: String? = nil, abiJson: String? = nil,
                functionName: String? = nil, args: [AnyEncodable]? = nil) {
        self.to = to
        self.value = value
        self.data = data
        self.abiJson = abiJson
        self.functionName = functionName
        self.args = args
    }
}
