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
// Copyright (c) 2024 the Swift WebAuthn project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift WebAuthn project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

/// A globally unique ID identifying an authenticator.
///
/// Each authenticator has an Authenticator Attestation Globally Unique Identifier or **AAGUID**, which is a 128-bit identifier indicating the type (e.g. make and model) of the authenticator. The AAGUID MUST be chosen by its maker to be identical across all substantially identical authenticators made by that maker, and different (with high probability) from the AAGUIDs of all other types of authenticators. The AAGUID for a given type of authenticator SHOULD be randomly generated to ensure this.
///
/// The Relying Party MAY use the AAGUID to infer certain properties of the authenticator, such as certification level and strength of key protection, using information from other sources. The Relying Party MAY use the AAGUID to attempt to identify the maker of the authenticator without requesting and verifying attestation, but the AAGUID is not provably authentic without attestation.
/// - SeeAlso: [WebAuthn Leven 3 Editor's Draft §6. WebAuthn Authenticator Model](https://w3c.github.io/webauthn/#aaguid)
public struct AuthenticatorAttestationGloballyUniqueID: Hashable, Sendable {
    /// The underlying UUID for the authenticator.
    public let id: UUID
    
    /// Initialize an AAGUID with a UUID.
    public init(uuid: UUID) {
        self.id = uuid
    }
    
    /// Initialize an AAGUID with a byte sequence.
    ///
    /// This sequence must be of length ``AuthenticatorAttestationGloballyUniqueID/size``.
    @inlinable
    public init?(bytes: some BidirectionalCollection<UInt8>) {
        let uuidSize = MemoryLayout<uuid_t>.size
        assert(uuidSize == Self.size, "Size of uuid_t (\(uuidSize)) does not match Self.size (\(Self.size))!")
        guard bytes.count == uuidSize else { return nil }
        self.init(uuid: UUID(uuid: bytes.casting()))
    }
    
    /// Initialize an AAGUID with a string-based UUID.
    @inlinable
    public init?(uuidString: String) {
        guard let uuid = UUID(uuidString: uuidString)
        else { return nil }
        
        self.init(uuid: uuid)
    }
    
    /// Access the AAGUID as an encoded byte sequence.
    @inlinable
    public var bytes: [UInt8] { withUnsafeBytes(of: id) { Array($0) } }
    
    /// The identifier of an anonymized authenticator, set to a byte sequence of 16 zeros.
    public static let anonymous = AuthenticatorAttestationGloballyUniqueID(uuid: .init(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)))
    
    /// The byte length of an encoded identifer.
    public static let size: Int = 16
}

/// A shorthand for an ``AuthenticatorAttestationGloballyUniqueID``
typealias AAGUID = AuthenticatorAttestationGloballyUniqueID

extension AuthenticatorAttestationGloballyUniqueID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        id = try container.decode(UUID.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}
