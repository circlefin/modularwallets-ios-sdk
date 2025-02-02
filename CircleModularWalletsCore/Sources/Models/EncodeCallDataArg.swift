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

public struct EncodeCallDataArg: Encodable {

    /// In SmartAccount.encodeCalls
    ///
    /// - to: required
    /// - value: optional, default 0
    /// - data: optional, If no data returns “0x”
    ///
    /// In EncodeFunctionData
    ///
    /// - abiJson: required
    /// - functionName: required
    /// - args: optional

    public let to: String
    public let value: BigInt?
    public let data: String?
    public let abiJson: String?
    public let functionName: String?
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
