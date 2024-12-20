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

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift WebAuthn open source project
//
// Copyright (c) 2022 the Swift WebAuthn project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift WebAuthn project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

/// The `PublicKeyCredentialRequestOptions` gets passed to the WebAuthn API (`navigator.credentials.get()`)
///
/// When encoding using `Encodable`, the byte arrays are encoded as base64url.
///
/// - SeeAlso: https://www.w3.org/TR/webauthn-2/#dictionary-assertion-options
public struct PublicKeyCredentialRequestOptions: Codable, Sendable {
    /// A challenge that the authenticator signs, along with other data, when producing an authentication assertion
    public let challenge: URLEncodedBase64

    /// A time, in seconds, that the caller is willing to wait for the call to complete. This is treated as a
    /// hint, and may be overridden by the client.
    ///
    /// - Note: When encoded, this value is represented in milleseconds as a ``UInt32``.
    /// See https://www.w3.org/TR/webauthn-2/#dictionary-assertion-options
    public let timeout: Duration?

    /// The ID of the Relying Party making the request.
    ///
    /// This is configured on ``WebAuthnManager`` before its ``WebAuthnManager/beginAuthentication(timeout:allowCredentials:userVerification:)`` method is called.
    /// - Note: When encoded, this field appears as `rpId` to match the expectations of `navigator.credentials.get()`.
    public let relyingParty: PublicKeyCredentialRelyingPartyEntity

    /// Optionally used by the client to find authenticators eligible for this authentication ceremony.
    public let allowCredentials: [PublicKeyCredentialDescriptor]?

    /// Specifies whether the user should be verified during the authentication ceremony.
    public let userVerification: UserVerificationRequirement?

    /// Additional parameters requesting additional processing by the client and authenticator.
    //public let extensions: [String: Any]?

    private enum CodingKeys: String, CodingKey {
        case challenge
        case timeout
        case rpID = "rpId"
        case allowCredentials
        case userVerification
    }

    init(challenge: URLEncodedBase64,
         timeout: Duration? = nil,
         relyingParty: PublicKeyCredentialRelyingPartyEntity,
         allowCredentials: [PublicKeyCredentialDescriptor]? = nil,
         userVerification: UserVerificationRequirement? = nil) {
        self.challenge = challenge
        self.timeout = timeout
        self.relyingParty = relyingParty
        self.allowCredentials = allowCredentials
        self.userVerification = userVerification
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let challengeStr = try container.decode(String.self, forKey: .challenge)
        challenge = URLEncodedBase64(challengeStr)

        if let timeoutDouble = try container.decodeIfPresent(Double.self, forKey: .timeout) {
            timeout = Duration.milliseconds(timeoutDouble)
        } else {
            timeout = nil
        }

        let rpID = try container.decode(String.self, forKey: .rpID)
        relyingParty = .init(id: rpID, name: "")

        allowCredentials = try container.decodeIfPresent([PublicKeyCredentialDescriptor].self, forKey: .allowCredentials)
        userVerification = try container.decodeIfPresent(UserVerificationRequirement.self, forKey: .userVerification)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(challenge.asString(), forKey: .challenge)
        try container.encodeIfPresent(timeout?.milliseconds, forKey: .timeout)
        try container.encodeIfPresent(relyingParty.id, forKey: .rpID)
        try container.encodeIfPresent(allowCredentials, forKey: .allowCredentials)
        try container.encodeIfPresent(userVerification, forKey: .userVerification)
    }
}

/// The Relying Party may require user verification for some of its operations but not for others, and may use this
/// type to express its needs.
public enum UserVerificationRequirement: String, Codable, Sendable {
    /// The Relying Party requires user verification for the operation and will fail the overall ceremony if the
    /// user wasn't verified.
    case required
    /// The Relying Party prefers user verification for the operation if possible, but will not fail the operation.
    case preferred
    /// The Relying Party does not want user verification employed during the operation (e.g., in the interest of
    /// minimizing disruption to the user interaction flow).
    case discouraged
}
