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

public protocol SmartAccount {
    var client: Client { get }
    var entryPoint: EntryPoint { get }
    var userOperation: UserOperationConfiguration? { get async }

    func getAddress() -> String
    func encodeCalls(args: [EncodeCallDataArg]) -> String?
    func getFactoryArgs() async throws -> (String, String)?
    func getNonce(key: BigInt?) async throws -> BigInt
    func getStubSignature<T: UserOperation>(userOp: T) -> String
    func sign(hex: String) async throws -> String
    func signMessage(message: String) async throws -> String
    func signTypedData(typedData: String) async throws -> String
    func signUserOperation(chainId: Int, userOp: UserOperationV07) async throws -> String
    func getInitCode() async -> String?
}

public struct UserOperationConfiguration {
    var estimateGas: ((UserOperation) async -> EstimateUserOperationGasResult?)?
}
