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

/// Protocol representing a public key credential.
public protocol PublicKeyCredential: Encodable, Sendable {

    /// The unique identifier for the credential.
    var id: String { get }

    /// The type of the credential.
    var type: CredentialType { get }

    /// The attachment type of the authenticator.
    var authenticatorAttachment: AuthenticatorAttachment? { get }

    /// The response from the authenticator.
    var response: AuthenticatorResponse { get }

    /// Optional client extension results.
    var clientExtensionResults: AuthenticationExtensionsClientOutputs? { get }
}

/// Protocol representing a response from an authenticator.
public protocol AuthenticatorResponse: Codable, Sendable {

    /// The client data in JSON format.
    var clientDataJSON: URLEncodedBase64 { get }
}
