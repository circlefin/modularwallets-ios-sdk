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

/// A parsed version of the `clientDataJSON` received from the authenticator. The `clientDataJSON` is a
/// representation of the options we passed to the WebAuthn API (`.get()`/ `.create()`).
public struct CollectedClientData: Codable, Hashable, Sendable {
    enum CollectedClientDataVerifyError: Error {
        case ceremonyTypeDoesNotMatch
        case challengeDoesNotMatch
        case originDoesNotMatch
    }

    public enum CeremonyType: String, Codable, Sendable {
        case create = "webauthn.create"
        case assert = "webauthn.get"
    }

    /// Contains the string "webauthn.create" when creating new credentials,
    /// and "webauthn.get" when getting an assertion from an existing credential
    public let type: CeremonyType
    /// The challenge that was provided by the Relying Party
    public let challenge: URLEncodedBase64
    public let origin: String

    func verify(storedChallenge: [UInt8],
                ceremonyType: CeremonyType,
                relyingPartyOrigin: String? = nil) throws {
        guard type == ceremonyType else {
            throw CollectedClientDataVerifyError.ceremonyTypeDoesNotMatch
        }

        guard challenge == storedChallenge.base64URLEncodedString() else {
            throw CollectedClientDataVerifyError.challengeDoesNotMatch
        }

        guard let relyingPartyOrigin else { return }

        guard origin == relyingPartyOrigin else {
            throw CollectedClientDataVerifyError.originDoesNotMatch
        }
    }
}
