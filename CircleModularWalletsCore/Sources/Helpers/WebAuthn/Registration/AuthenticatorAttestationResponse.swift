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
import SwiftCBOR

/// The response from the authenticator device for the creation of a new public key credential.
public struct AuthenticatorAttestationResponse: AuthenticatorResponse, Encodable, Sendable {
    /// JSON-compatible serialization of client data passed to the authenticator by the client in order to generate this credential.
    public let clientDataJSON: URLEncodedBase64

    /// This attribute contains an attestation object, which is opaque to, and cryptographically protected against tampering by, the client.
    public let attestationObject: URLEncodedBase64

    /// The authenticator data structure encodes contextual bindings made by the authenticator.
    public var authenticatorData: URLEncodedBase64? = nil

    /// The transports that the authenticator is believed to support, or an empty sequence if the information is unavailable.
    public var transports: [String]? = nil

    /// The public key of the credential
    public var publicKey: URLEncodedBase64? = nil

    /// The COSEAlgorithmIdentifier for the credential public key
    public var publicKeyAlgorithm: Int? = nil

    private enum CodingKeys: String, CodingKey {
        case clientDataJSON
        case attestationObject
        case authenticatorData
        case transports
        case publicKey
        case publicKeyAlgorithm
    }

    public init(rawClientDataJSON: [UInt8], rawAttestationObject: [UInt8]) {
        self.clientDataJSON = rawClientDataJSON.base64URLEncodedString()
        self.attestationObject = rawAttestationObject.base64URLEncodedString()

        guard let parsed = try? ParsedAuthenticatorAttestationResponse(
            rawClientDataJSON: rawClientDataJSON,
            rawAttestationObject: rawAttestationObject
        ) else { return }

        self.authenticatorData = parsed.authenticatorData.base64URLEncodedString()

        if let attestedCredentialData = parsed.attestationObject.authenticatorData.attestedData {
            self.publicKey = attestedCredentialData.publicKey.base64URLEncodedString()

            guard let credentialPublicKey = try? CredentialPublicKey(publicKeyBytes: attestedCredentialData.publicKey) else { return }

            self.publicKeyAlgorithm = credentialPublicKey.key.algorithm.rawValue
        }
    }
}

/// A parsed version of `AuthenticatorAttestationResponse`
struct ParsedAuthenticatorAttestationResponse {
    let clientData: CollectedClientData
    let attestationObject: AttestationObject
    let authenticatorData: [UInt8]

    init(rawClientDataJSON: [UInt8], rawAttestationObject: [UInt8]) throws {
        // assembling clientData
        let clientData = try JSONDecoder().decode(CollectedClientData.self, from: Data(rawClientDataJSON))
        self.clientData = clientData

        // assembling attestationObject
        let attestationObjectData = Data(rawAttestationObject)
        guard let decodedAttestationObject = try? CBOR.decode([UInt8](attestationObjectData), options: CBOROptions(maximumDepth: 16)) else {
            throw WebAuthnError.invalidAttestationObject
        }

        guard let authData = decodedAttestationObject["authData"],
            case let .byteString(authDataBytes) = authData else {
            throw WebAuthnError.invalidAuthData
        }

        authenticatorData = authDataBytes

        guard let formatCBOR = decodedAttestationObject["fmt"],
            case let .utf8String(format) = formatCBOR,
            let attestationFormat = AttestationFormat(rawValue: format) else {
            throw WebAuthnError.invalidFmt
        }

        guard let attestationStatement = decodedAttestationObject["attStmt"] else {
            throw WebAuthnError.missingAttStmt
        }

        attestationObject = AttestationObject(
            authenticatorData: try AuthenticatorData(bytes: authDataBytes),
            rawAuthenticatorData: authDataBytes,
            format: attestationFormat,
            attestationStatement: attestationStatement
        )
    }
}
