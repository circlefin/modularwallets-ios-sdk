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

/// The owner identifier type for address mapping.
public enum OwnerIdentifierType: String, Codable {
    case eoa = "EOAOWNER"
    case webAuthn = "WEBAUTHOWNER"
}

/// The EOA identifier for address mapping.
public struct EOAIdentifier: Codable {

    /// The wallet address.
    let address: String
}

/// The WebAuthn identifier for address mapping.
public struct WebAuthnIdentifier: Codable {

    /// The public key X.
    let publicKeyX: String
    
    /// The public key Y.
    let publicKeyY: String
}

/// The base case of owner for address mapping.
public class AddressMappingOwner: Codable {
    
    /// The owner identifier type for address mapping. See [OwnerIdentifierType].
    let type: String

    public init(type: String) {
        self.type = type
    }

    enum CodingKeys: String, CodingKey {
        case type
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
    }

    static func create(from decoder: Decoder) throws -> AddressMappingOwner {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case OwnerIdentifierType.eoa.rawValue:
            return try EoaAddressMappingOwner(from: decoder)
        case OwnerIdentifierType.webAuthn.rawValue:
            return try WebAuthnAddressMappingOwner(from: decoder)
        default:
            return try AddressMappingOwner(from: decoder)
        }
    }
}

/// The EOA owner for address mapping.
public class EoaAddressMappingOwner: AddressMappingOwner {
    
    /// The struct of EOA identifier.
    let identifier: EOAIdentifier

    public init(_ identifier: EOAIdentifier) {
        self.identifier = identifier
        super.init(type: OwnerIdentifierType.eoa.rawValue)
    }

    enum CodingKeys: String, CodingKey {
        case identifier
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(EOAIdentifier.self, forKey: .identifier)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
    }
}

/// The WebAuthn owner for address mapping.
public class WebAuthnAddressMappingOwner: AddressMappingOwner {
    
    /// The struct of WebAuthn identifier.
    let identifier: WebAuthnIdentifier

    public init(_ identifier: WebAuthnIdentifier) {
        self.identifier = identifier
        super.init(type: OwnerIdentifierType.webAuthn.rawValue)
    }

    enum CodingKeys: String, CodingKey {
        case identifier
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(WebAuthnIdentifier.self, forKey: .identifier)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
    }
}

/// The response from adding an address mapping.
public struct CreateAddressMappingResult: Codable {
    
    /// The mapping ID.
    public let id: String

    /// The blockchain identifier.
    public let blockchain: String

    /// The owner information.
    public let owner: AddressMappingOwner

    /// The wallet address.
    public let walletAddress: String

    /// The creation date (ISO 8601 format).
    public let createDate: String

    /// The last update date (ISO 8601 format).
    public let updateDate: String

    enum CodingKeys: String, CodingKey {
        case id
        case blockchain
        case owner
        case walletAddress
        case createDate
        case updateDate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        blockchain = try container.decode(String.self, forKey: .blockchain)
        walletAddress = try container.decode(String.self, forKey: .walletAddress)
        createDate = try container.decode(String.self, forKey: .createDate)
        updateDate = try container.decode(String.self, forKey: .updateDate)

        owner = try AddressMappingOwner.create(from: container.superDecoder(forKey: .owner))
    }
}
