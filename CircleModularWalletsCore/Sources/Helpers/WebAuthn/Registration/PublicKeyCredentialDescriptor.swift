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

/// Information about a generated credential.
///
/// When encoding using `Encodable`, `id` is encoded as base64url.
public struct PublicKeyCredentialDescriptor: Codable, Sendable {
    /// Defines hints as to how clients might communicate with a particular authenticator in order to obtain an
    /// assertion for a specific credential
    public enum AuthenticatorTransport: String, Codable, Sendable {
        /// Indicates the respective authenticator can be contacted over removable USB.
        case usb
        /// Indicates the respective authenticator can be contacted over Near Field Communication (NFC).
        case nfc
        /// Indicates the respective authenticator can be contacted over Bluetooth Smart (Bluetooth Low Energy / BLE).
        case ble
        /// Indicates the respective authenticator can be contacted using a combination of (often separate)
        /// data-transport and proximity mechanisms. This supports, for example, authentication on a desktop
        /// computer using a smartphone.
        case hybrid
        /// Indicates the respective authenticator is contacted using a client device-specific transport, i.e., it is
        /// a platform authenticator. These authenticators are not removable from the client device.
        case `internal`
    }

    /// Will always be ``CredentialType/publicKey``
    public let type: CredentialType

    /// The sequence of bytes representing the credential's ID
    public let id: String

    /// The types of connections to the client/browser the authenticator supports
    public let transports: [AuthenticatorTransport]?

    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case transports
    }

    public init(type: CredentialType = .publicKey,
                id: String,
                transports: [AuthenticatorTransport]? = nil) {
        self.type = type
        self.id = id
        self.transports = transports
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let typeStr = try container.decode(String.self, forKey: .type)
        type = CredentialType(typeStr)

        id = try container.decode(String.self, forKey: .id)
        transports = try container.decodeIfPresent([AuthenticatorTransport].self, forKey: .transports)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(transports, forKey: .transports)
    }
}
