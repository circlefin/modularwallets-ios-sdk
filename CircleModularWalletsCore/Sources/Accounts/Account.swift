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

/// Protocol representing an account.
public protocol Account {
    /// The type of the signed data.
    associatedtype T: Decodable

    /// Retrieves the address of the account.
    ///
    /// - Returns: The address of the account.
    func getAddress() -> String

    /// Signs the given hex data.
    ///
    /// - Parameters:
    ///   - hex: The hex data to sign.
    ///
    /// - Returns: The signed data of type `T`.
    func sign(hex: String) async throws -> T

    /// Signs the given message.
    ///
    /// - Parameters:
    ///   - message: The message to sign.
    ///
    /// - Returns: The signed message of type `T`.
    func signMessage(message: String) async throws -> T

    /// Signs the given typed data.
    ///
    /// - Parameters:
    ///   - typedData: The typed data to sign.
    ///
    /// - Returns: The signed typed data of type `T`.
    func signTypedData(typedData: String) async throws -> T
}
