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

/// Creates a [LocalAccount] instance from a hexadecimal private key string.
///
/// The underlying account implementation is [Web3swiftLocalAccount].
///
/// - Parameter privateKey: The private key as a hexadecimal string.
///
/// - Returns: A [LocalAccount] instance derived from the provided private key.
public func privateKeyToAccount(_ privateKey: String) throws -> LocalAccount {
    do {
        let account = try Web3swiftLocalAccount(privateKeyHex: privateKey)
        return LocalAccount(account)
    } catch {
        throw BaseError(shortMessage: "Failed to create Web3swiftLocalAccount: \(error)")
    }
}

/// Represents a local account with signing capabilities.
///
/// Instances are typically created via factory functions like `mnemonicToAccount` or `privateKeyToAccount`.
public struct LocalAccount: Account {

    /// The underlying `Account` instance that this `LocalAccount` will  delegate its operations to.
    /// This delegate is responsible for the actual cryptographic operations and key management.
    let delegate: any Account
    
    /// Initializes a new LocalAccount with the given delegate.
    ///
    /// - Parameter delegate: The Account instance that will handle the actual operations.
    public init(_ delegate: any Account) {
        self.delegate = delegate
    }

    /// Retrieves the address of the local account.
    /// 
    /// - Returns: The address of the local account.
    public func getAddress() -> String {
        return delegate.getAddress()
    }

    /// Signs the given hex string.
    ///
    /// - Parameter messageHash: The hex string to be signed.
    ///
    /// - Returns: The signed hex string.
    /// - Throws: A `BaseError` if signing fails.
    public func sign(messageHash: String) async throws -> String {
        let result = try await delegate.sign(messageHash: messageHash)
        guard let stringResult = result as? String else {
            throw BaseError(shortMessage: "Expected String result from delegate.sign, got \(type(of: result))")
        }
        return stringResult
    }

    /// Signs the given message.
    ///
    /// - Parameter message: The message to be signed.
    ///
    /// - Returns: The signed message.
    /// - Throws: A `BaseError` if signing fails.
    public func signMessage(message: String) async throws -> String {
        let result = try await delegate.signMessage(message: message)
        guard let stringResult = result as? String else {
            throw BaseError(shortMessage: "Expected String result from delegate.signMessage, got \(type(of: result))")
        }
        return stringResult
    }

    /// Signs the given typed data.
    ///
    /// - Parameter typedData: The typed data to be signed.
    ///
    /// - Returns: The signed typed data.
    /// - Throws: A `BaseError` if signing fails.
    public func signTypedData(typedData: String) async throws -> String {
        let result = try await delegate.signTypedData(typedData: typedData)
        guard let stringResult = result as? String else {
            throw BaseError(shortMessage: "Expected String result from delegate.signTypedData, got \(type(of: result))")
        }
        return stringResult
    }
}
