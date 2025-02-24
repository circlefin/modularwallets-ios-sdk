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
import Web3Core
import web3swift
import BigInt

/// Creates a WebAuthn account.
///
/// - Parameters:
///   - credential: The WebAuthn credential associated with the account.
///
/// - Returns: The created WebAuthn account.
public func toWebAuthnAccount(_ credential: WebAuthnCredential) -> WebAuthnAccount {
    return .init(credential: credential)
}

/// Represents a WebAuthn account.
public struct WebAuthnAccount: Account {

    /// The WebAuthn credential associated with the account.
    let credential: WebAuthnCredential

    /// Retrieves the address of the WebAuthn account.
    ///
    /// - Returns: The public key associated with the WebAuthn credential.
    public func getAddress() -> String {
        return credential.publicKey
    }

    /// Signs the given hex data.
    ///
    /// - Parameters:
    ///   - hex: The hex data to sign.
    ///
    /// - Returns: The result of the signing operation.
    /// - Throws: A `BaseError` if the credential request fails.
    public func sign(hex: String) async throws -> SignResult {
        do {
            /// Step 1. Get RequestOptions
            let option = try WebAuthnUtils.getRequestOption(
                rpId: credential.rpId,
                allowCredentialId: credential.id,
                hex: hex)

            /// Step 2. Get credential
            let credential = try await WebAuthnHandler.shared.signInWith(option: option)
            guard let authCredential = credential as? AuthenticationCredential,
                  let response = authCredential.response as? AuthenticatorAssertionResponse else {
                let error = WebAuthnCredentialError.authenticationCredentialCastingFailed
                throw BaseError(shortMessage: error.localizedDescription,
                                args: .init(cause: error, name: String(describing: error)))
            }

            let userVerification = option.userVerification?.rawValue ?? ""
            guard let webAuthnData = authCredential.toWebAuthnData(userVerification: userVerification) else {
                throw BaseError(shortMessage: "Failed toWebAuthnData() from the AuthenticationCredential")
            }

            let signatureHex = HexUtils.bytesToHex(response.signature.decodedBytes)
            guard let (rData, sData) = Utils.extractRSFromDER(signatureHex) else {
                throw BaseError(shortMessage: "Can't extract the r, s from a DER-encoded ECDSA signature")
            }

            let adjustedSignature = WebAuthnAccount.adjustSignature((r: rData, s: sData))
            let adjustedSignatureDerFormatHex = Utils.packRSIntoDer(adjustedSignature)

            let signResult = SignResult(
                signature: adjustedSignatureDerFormatHex,
                webAuthn: webAuthnData,
                raw: authCredential)

            return signResult
        } catch let error as BaseError {
            throw error
        } catch {
            throw BaseError(shortMessage: error.localizedDescription,
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    /// Signs the given message.
    ///
    /// - Parameters:
    ///   - message: The message to sign.
    ///
    /// - Returns: The result of the signing operation.
    /// - Throws: A `BaseError` if the credential request fails.
    public func signMessage(message: String) async throws -> SignResult {
        guard let hash = Utilities.hashPersonalMessage(Data(message.utf8)) else {
            throw BaseError(shortMessage: "Failed to hash message: \"\(message)\"")
        }

        let hex = HexUtils.dataToHex(hash)
        return try await sign(hex: hex)
    }

    /// Signs the given typed data.
    ///
    /// - Parameters:
    ///   - typedData: The typed data to sign.
    ///
    /// - Returns: The result of the signing operation.
    /// - Throws: A `BaseError` if the credential request fails.
    public func signTypedData(typedData: String) async throws -> SignResult {
        guard let typedDataObj = try? EIP712Parser.parse(typedData),
              let hash = try? typedDataObj.signHash() else {
            throw BaseError(shortMessage: "Failed to hash TypedData: \"\(typedData)\"")
        }

        let hex = HexUtils.dataToHex(hash)
        return try await sign(hex: hex)
    }
}

extension WebAuthnAccount {

    // MARK: Internal Usage

    static func adjustSignature(_ signature: (r: Data, s: Data)) -> (Data, Data) {
        let P256_N = BigUInt("FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551", radix: 16) ?? .zero
        let P256_N_DIV_2 = P256_N >> 1
        let sBigUInt = BigUInt(signature.s)

        if sBigUInt > P256_N_DIV_2 {
            return (signature.r, (P256_N - sBigUInt).serialize())
        } else {
            return (signature.r, signature.s)
        }
    }

}
