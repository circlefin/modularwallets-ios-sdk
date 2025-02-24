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
import AuthenticationServices
import Web3Core

/// Enum representing the WebAuthn modes.
public enum WebAuthnMode {

    /// Mode for registering a new credential.
    case register

    /// Mode for logging in with an existing credential.
    case login
}

enum WebAuthnCredentialError: Error {
    case register
    case registerUnknownAuthType
    case requestUnknownAuthType
    case registrationCredentialCastingFailed
    case authenticationCredentialCastingFailed
    case getPublicKeyFailed
}

/// Logs in or registers a user and returns a ``WebAuthnCredential``.
///
/// - Parameters:
///   - transport: The transport used to communicate with the RP API.
///   - userName: The username of the user (required for `WebAuthnMode.Register`).
///   - mode: The mode of the WebAuthn credential.
///
/// - Returns: The created `WebAuthnCredential`.
///
/// - Throws: A `BaseError` if `userName` is `nil` for `WebAuthnMode.Register`.
public func toWebAuthnCredential(
    transport: Transport,
    userName: String? = nil,
    mode: WebAuthnMode
) async throws -> WebAuthnCredential {
    switch mode {
    case .register:
        guard let userName else {
            let error = WebAuthnCredentialError.register
            throw BaseError(shortMessage: "The userName cannot be nil",
                            args: .init(cause: error, name: String(describing: error)))
        }
        return try await WebAuthnCredential.register(transport: transport, userName: userName)

    case .login:
        return try await WebAuthnCredential.login(transport: transport)
    }
}

/// Data structure representing a P-256 WebAuthn Credential.
public struct WebAuthnCredential: RpRpcApi, Sendable {

    /// The unique identifier for the credential.
    public let id: String

    /// The public key associated with the credential. (serialized hex string)
    public let publicKey: String

    /// The PublicKeyCredential object returned by the Web Authentication API.
    public let raw: PublicKeyCredential

    /// The relying party identifier.
    public let rpId: String

    static func register(transport: Transport,
                         userName: String) async throws -> WebAuthnCredential {
        do {
            /// Step 1. RP getRegistrationOptions
            logger.webAuthn.debug("Register userName \(userName)")
            let option = try await getRegistrationOptions(transport: transport, userName: userName)

            /// Step 2. Create credential
            let registerCredential = try await WebAuthnHandler.shared.signUpWith(option: option)
            guard let credential = registerCredential as? RegistrationCredential else {
                let error = WebAuthnCredentialError.registrationCredentialCastingFailed
                throw BaseError(shortMessage: error.localizedDescription,
                                args: .init(cause: error, name: String(describing: error)))
            }

            /// Step 3. RP getRegistrationVerification
            _ = try await getRegistrationVerification(
                transport: transport,
                registrationCredential: credential
            )

            guard let attestationResponse = credential.response as? AuthenticatorAttestationResponse,
                  let publicKey = attestationResponse.publicKey else {
                let error = WebAuthnCredentialError.getPublicKeyFailed
                throw BaseError(shortMessage: error.localizedDescription,
                                args: .init(cause: error, name: String(describing: error)))
            }

            /// After the server verifies the registration and creates the user account, sign in the user with the new account.
            /// Step 4. Parse and serialized public key
            let serializedPublicKey = HexUtils.bytesToHex(publicKey.decodedBytes)
            return WebAuthnCredential(id: credential.id,
                                      publicKey: serializedPublicKey,
                                      raw: credential,
                                      rpId: option.relyingParty.id)
        } catch let error as BaseError {
            throw error
        } catch {
            throw BaseError(shortMessage: error.localizedDescription,
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    static func login(transport: Transport) async throws -> WebAuthnCredential {
        do {
            /// Step 1. RP getLoginOptions
            logger.webAuthn.debug("Login")
            let option = try await getLoginOptions(transport: transport)

            /// Step 2. Get credential
            let loginCredential = try await WebAuthnHandler.shared.signInWith(option: option)
            guard let credential = loginCredential as? AuthenticationCredential else {
                let error = WebAuthnCredentialError.authenticationCredentialCastingFailed
                throw BaseError(shortMessage: error.localizedDescription,
                                args: .init(cause: error, name: String(describing: error)))
            }

            /// Step 3. RP getLoginVerification
            let loginResult = try await getLoginVerification(
                transport: transport,
                authenticationCredential: credential
            )

            /// After the server verifies the assertion, sign in the user.
            /// Step 4. Parse and serialized public key
            let coseKey = try Utils.pemToCOSE(pemKey: loginResult.publicKey)
            let serializedPublicKey = HexUtils.bytesToHex(coseKey)
            return WebAuthnCredential(id: credential.id,
                                      publicKey: serializedPublicKey,
                                      raw: credential,
                                      rpId: option.relyingParty.id)
        } catch let error as BaseError {
            throw error
        } catch {
            throw BaseError(shortMessage: error.localizedDescription,
                            args: .init(cause: error, name: String(describing: error)))
        }
    }
}
