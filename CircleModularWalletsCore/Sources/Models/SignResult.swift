//
// Copyright (c) 2024, Circle Internet Group, Inc. All rights reserved.
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

public struct SignResult: Decodable {
    /// Hex
    public let signature: String
    public let webAuthn: WebAuthnData
    public let raw: AuthenticationCredential
}

public struct WebAuthnData: Decodable {
    /// Hex
    public let authenticatorData: String
    /// Base64URL decoded
    public let clientDataJSON: String
    public let challengeIndex: Int
    public let typeIndex: Int
    public let userVerificationRequired: Bool
}

extension AuthenticationCredential {

    func toWebAuthnData(userVerification: String) -> WebAuthnData? {
        guard let response = response as? AuthenticatorAssertionResponse else {
            return nil
        }

        let decodedJSON = String(bytes: response.clientDataJSON.decodedBytes ?? [], encoding: .utf8) ?? ""
        let authenticatorData = HexUtils.bytesToHex(response.authenticatorData.decodedBytes)
        let challengeIndex: Int = decodedJSON.index(of: "\"challenge\"") ?? 0
        let typeIndex: Int = decodedJSON.index(of: "\"type\"") ?? 0

        return WebAuthnData(
            authenticatorData: authenticatorData,
            clientDataJSON: decodedJSON,
            challengeIndex: challengeIndex,
            typeIndex: typeIndex,
            userVerificationRequired: userVerification == UserVerificationRequirement.required.rawValue
        )
    }
}

