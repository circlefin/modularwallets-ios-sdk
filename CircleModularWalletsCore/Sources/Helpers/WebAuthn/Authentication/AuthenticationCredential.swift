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

/// The unprocessed response received from `navigator.credentials.get()`.
public struct AuthenticationCredential: PublicKeyCredential, Codable, Sendable {

    /// The credential ID of the newly created credential.
    public let id: String

    /// Value will always be ``CredentialType/publicKey`` (for now)
    public let type: CredentialType

    /// An authenticators' attachment modalities.
    public let authenticatorAttachment: AuthenticatorAttachment?

    /// The raw credential ID of the newly created credential.
    public let rawID: URLEncodedBase64

    /// The attestation response from the authenticator.
    /// In fact, it is stored in AuthenticatorAssertionResponse
    public let response: AuthenticatorResponse

    /// Reports the authenticator attachment modality in effect at the time the navigator.credentials.create() or
    /// navigator.credentials.get() methods successfully complete
    public let clientExtensionResults: AuthenticationExtensionsClientOutputs?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case authenticatorAttachment
        case rawID = "rawId"
        case response
        case clientExtensionResults
    }

    init(id: String,
         type: CredentialType,
         authenticatorAttachment: AuthenticatorAttachment? = nil,
         rawID: URLEncodedBase64,
         response: AuthenticatorAssertionResponse,
         clientExtensionResults: AuthenticationExtensionsClientOutputs? = nil) {
        self.id = id
        self.type = type
        self.authenticatorAttachment = authenticatorAttachment
        self.rawID = rawID
        self.response = response
        self.clientExtensionResults = clientExtensionResults
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(CredentialType.self, forKey: .type)
        authenticatorAttachment = try container.decode(AuthenticatorAttachment.self, forKey: .authenticatorAttachment)
        rawID = try container.decode(URLEncodedBase64.self, forKey: .rawID)
        response = try container.decode(AuthenticatorAssertionResponse.self, forKey: .response)
        clientExtensionResults = try container.decode(AuthenticationExtensionsClientOutputs.self, forKey: .clientExtensionResults)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(authenticatorAttachment, forKey: .authenticatorAttachment)
        try container.encode(rawID.asString(), forKey: .rawID)
        try container.encode(response, forKey: .response)
        try container.encodeIfPresent(clientExtensionResults, forKey: .clientExtensionResults)
    }
}
