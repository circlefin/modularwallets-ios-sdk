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

/// The type of credential being used.
///
/// Only ``CredentialType/publicKey`` is supported by WebAuthn.
/// - SeeAlso: [Credential Management Level 1 Editor's Draft §2.1.2. Credential Type Registry](https://w3c.github.io/webappsec-credential-management/#sctn-cred-type-registry)
/// - SeeAlso: [WebAuthn Level 3 Editor's Draft §5.1. PublicKeyCredential Interface](https://w3c.github.io/webauthn/#iface-pkcredential)
public struct CredentialType: UnreferencedStringEnumeration, Codable, Sendable {
    public var rawValue: String
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// A public key credential.
    /// - SeeAlso: [WebAuthn Level 3 Editor's Draft §5.1. PublicKeyCredential Interface](https://w3c.github.io/webauthn/#iface-pkcredential)
    public static let publicKey: Self = "public-key"
}
