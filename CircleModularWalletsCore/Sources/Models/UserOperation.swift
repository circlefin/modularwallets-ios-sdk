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

public protocol Copyable: AnyObject {
    func copy() -> Self
}

/// Protocol representing a user operation.
public protocol UserOperation: Codable, NSCopying, Copyable {

    /// The address of the sender.
    var sender: String? { get set }

    /// The nonce of the operation.
    var nonce: BigInt? { get set }

    /// The data to be sent in the call.
    var callData: String? { get set }

    /// The gas limit for the call.
    var callGasLimit: BigInt? { get set }

    /// The gas limit for verification.
    var verificationGasLimit: BigInt? { get set }

    /// The gas used before verification.
    var preVerificationGas: BigInt? { get set }

    /// The maximum priority fee per gas.
    var maxPriorityFeePerGas: BigInt? { get set }

    /// The maximum fee per gas.
    var maxFeePerGas: BigInt? { get set }

    /// The signature of the operation.
    var signature: String? { get set }
}

/// Enum to encapsulate different User Operation types
public enum UserOperationType: Codable {
    case v07(UserOperationV07)
}
