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
import BigInt

public protocol Copyable: AnyObject {
    func copy() -> Self
}

public protocol UserOperation: Codable, NSCopying, Copyable {
    var sender: String? { get set }
    var nonce: BigInt? { get set }
    var callData: String? { get set }
    var callGasLimit: BigInt? { get set }
    var verificationGasLimit: BigInt? { get set }
    var preVerificationGas: BigInt? { get set }
    var maxPriorityFeePerGas: BigInt? { get set }
    var maxFeePerGas: BigInt? { get set }
    var signature: String? { get set }
}

/// Enum to encapsulate different User Operation types
public enum UserOperationType: Codable {
    case v07(UserOperationV07)
}
