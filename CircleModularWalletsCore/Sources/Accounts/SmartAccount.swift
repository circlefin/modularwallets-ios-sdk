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

/// A Smart Account is an account whose implementation resides in a Smart Contract, and implements the ERC-4337 interface.
public protocol SmartAccount {

    /// The Client used to interact with the blockchain.
    var client: Client { get }

    /// The EntryPoint for the smart account.
    var entryPoint: EntryPoint { get }

    /// Configuration for the user operation.
    var userOperation: UserOperationConfiguration? { get async }

    /// Returns the address of the account.
    ///
    /// - Returns: The address of the smart account.
    func getAddress() -> String

    /// Encodes the given call data arguments.
    ///
    /// - Parameters:
    ///   - args: The call data arguments to encode.
    ///
    /// - Returns: The encoded call data.
    func encodeCalls(args: [EncodeCallDataArg]) -> String?

    /// Encodes the given call data arguments.
    ///
    /// - Parameters:
    ///   - args: The call data arguments to encode.
    ///
    /// - Returns: The encoded call data.
    func getFactoryArgs() async throws -> (String, String)?

    /// Returns the nonce for the Circle smart account.
    ///
    /// - Parameters:
    ///   - key: An optional key to retrieve the nonce for.
    ///
    /// - Returns: The nonce of the Circle smart account.
    func getNonce(key: BigInt?) async throws -> BigInt

    /// Returns the stub signature for the given user operation.
    ///
    /// - Parameters:
    ///   - userOp: The user operation to retrieve the stub signature for. The type `T` must be a subclass of `UserOperation`.
    ///
    /// - Returns: The stub signature.
    func getStubSignature<T: UserOperation>(userOp: T) -> String

    /// Signs the given hex data.
    ///
    /// - Parameters:
    ///   - hex: The hex data to sign.
    ///
    /// - Returns: The signed data.
    func sign(hex: String) async throws -> String

    /// Signs the given message.
    ///
    /// - Parameters:
    ///   - message: The message to sign.
    ///
    /// - Returns: The signed message.
    func signMessage(message: String) async throws -> String

    /// Signs the given typed data.
    ///
    /// - Parameters:
    ///   - typedData: The typed data to sign.
    ///
    /// - Returns: The signed typed data.
    func signTypedData(typedData: String) async throws -> String

    /// Signs the given user operation.
    ///
    /// - Parameters:
    ///   - chainId: The chain ID for the user operation. Default is the chain ID of the client.
    ///   - userOp: The user operation to sign.
    ///
    /// - Returns: The signed user operation.
    func signUserOperation(chainId: Int, userOp: UserOperationV07) async throws -> String

    /// Returns the initialization code for the Circle smart account.
    ///
    /// - Returns: The initialization code.
    func getInitCode() async -> String?
}

/// Configuration for the user operation.
public struct UserOperationConfiguration {
    var estimateGas: ((UserOperation) async -> EstimateUserOperationGasResult?)?
}
