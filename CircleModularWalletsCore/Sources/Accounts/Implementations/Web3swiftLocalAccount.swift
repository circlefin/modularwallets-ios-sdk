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
import web3swift
import Web3Core
import BigInt

/// An internal implementation of `Account` that uses web3swift for
/// cryptographic operations such as signing messages and transactions.
/// This class directly handles interactions with the web3swift library for local accounts.
class Web3swiftLocalAccount: Account {
    public typealias T = String
    private let keystore: AbstractKeystore
    private let privateKeyData: Data
    private let address: EthereumAddress

    /// Initializes a new Web3LocalAccount with the given private key.
    ///
    /// - Parameter privateKey: The private key data associated with this local account,
    ///                         used for signing operations.
    /// - Throws: An `BaseError` if the private key is invalid or if the keystore cannot be created.
    init(privateKey: Data) throws {
        self.privateKeyData = privateKey

        // Create keystore from private key
        guard let keystore = try? EthereumKeystoreV3(privateKey: privateKey, password: "") else {
            throw BaseError(shortMessage: "Failed to create keystore from private key")
        }
        self.keystore = keystore

        // Get Ethereum address from keystore
        guard let address = keystore.addresses?.first else {
            throw BaseError(shortMessage: "Keystore does not contain any addresses")
        }
        
        self.address = address
    }

    /// Alternative initializer that takes a hex string private key.
    ///
    /// - Parameter privateKeyHex: The hex string representation of the private key.
    /// - Throws: An `BaseError` if the private key is invalid or cannot be converted to Data.
    convenience init(privateKeyHex: String) throws {
        guard let privateKey = HexUtils.hexToData(hex: privateKeyHex) else {
            throw BaseError(shortMessage: "Invalid private key hex string")
        }

        try self.init(privateKey: privateKey)
    }

    /// Retrieves the Ethereum address associated with the private key.
    ///
    /// - Returns: The Ethereum address for the current local account.
    public func getAddress() -> String {
        return address.address
    }

    /// Signs the given hexadecimal string, typically representing a pre-hashed message or transaction hash.
    /// This method uses web3swift's signing functionality without applying the Ethereum message prefix.
    ///
    /// - Parameter messageHash: The hexadecimal string (e.g., a 32-byte hash) to be signed.
    ///
    /// - Returns: The ECDSA signature as a serialized hex string (r + s + v).
    /// - Throws: A `BaseError` if signing fails or if the input hex string is invalid.
    public func sign(messageHash: String) async throws -> String {
        guard let data = HexUtils.hexToData(hex: messageHash) else {
            throw BaseError(shortMessage: "Invalid hex string for message hash")
        }

        // Ensure data is 32 bytes (hash length)
        if data.count != 32 {
            throw BaseError(shortMessage: "Invalid hash length: \(data.count) bytes, expected 32 bytes")
        }

        guard let signature = try? Web3Signer.signPersonalMessage(data, keystore: keystore, account: address, password: "", useHash: false) else {
            throw BaseError(shortMessage: "Failed to sign message hash")
        }

        return Utils.serializeSignature(signature)
    }

    /// Signs the given message string after applying the standard Ethereum message prefix
    /// (`\x19Ethereum Signed Message:\n` + message length).
    /// This method uses web3swift's personal sign functionality.
    ///
    /// - Parameter message: The plain string message to be signed. It will be UTF-8 encoded.
    ///
    /// - Returns: The ECDSA signature as a serialized hex string (r + s + v).
    /// - Throws: A `BaseError` if signing fails or if the message cannot be converted to UTF-8 data.
    public func signMessage(message: String) async throws -> String {
        guard let messageData = message.data(using: .utf8) else {
            throw BaseError(shortMessage: "Invalid message data")
        }

        guard let signature = try? Web3Signer.signPersonalMessage(messageData, keystore: keystore, account: address, password: "") else {
            throw BaseError(shortMessage: "Failed to sign message")
        }

        return Utils.serializeSignature(signature)
    }

    /// Signs the given EIP-712 typed data.
    /// The input `typedData` string is expected to be a JSON representation compliant with EIP-712.
    /// This method first computes the EIP-712 hash of the typed data and then signs this hash.
    ///
    /// - Parameter typedData: The EIP-712 typed data as a JSON string.
    ///
    /// - Returns: The ECDSA signature as a serialized hex string (r + s + v).
    /// - Throws: A `BaseError` if signing or hash computation fails.
    public func signTypedData(typedData: String) async throws -> String {
        guard let typedData = try? EIP712Parser.parse(typedData),
              let hashedTypedDataData = try? typedData.signHash() else {
            logger.localAccount.error("typedData signHash failure")
            throw BaseError(shortMessage: "Failed to hash TypedData: \"\(typedData)\"")
        }

        let hashedTypedData = HexUtils.dataToHex(hashedTypedDataData)

        return try await sign(messageHash: hashedTypedData)
    }
}
