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
import CryptoKit

/// This is what the authenticator device returned after we requested it to authenticate a user.
public struct AuthenticatorAssertionResponse: AuthenticatorResponse, Encodable, Sendable {
    /// Representation of what we passed to `navigator.credentials.get()`
    public let clientDataJSON: URLEncodedBase64

    /// Contains the authenticator data returned by the authenticator.
    public let authenticatorData: URLEncodedBase64

    /// Contains the raw signature returned from the authenticator
    public let signature: URLEncodedBase64

    /// Contains the user handle returned from the authenticator, or null if the authenticator did not return
    /// a user handle. Used by to give scope to credentials.
    public let userHandle: URLEncodedBase64?
}

//struct ParsedAuthenticatorAssertionResponse: Sendable {
//    let rawClientData: [UInt8]
//    let clientData: CollectedClientData
//    let rawAuthenticatorData: [UInt8]
//    let authenticatorData: AuthenticatorData
//    let signature: URLEncodedBase64
//    let userHandle: [UInt8]?
//
//    init(from authenticatorAssertionResponse: AuthenticatorAssertionResponse) throws {
//
//        if let rawClientData =  authenticatorAssertionResponse.clientDataJSON.decodedBytes {
//            self.rawClientData = rawClientData
//        } else {
//            self.rawClientData = []
//        }
//
//        clientData = try JSONDecoder().decode(CollectedClientData.self, from: Data(rawClientData))
//
//        if let rawAuthenticatorData = authenticatorAssertionResponse.authenticatorData.decodedBytes {
//            self.rawAuthenticatorData = rawAuthenticatorData
//        } else {
//            self.rawAuthenticatorData = []
//        }
//
//        authenticatorData = try AuthenticatorData(bytes: self.rawAuthenticatorData)
//        signature = authenticatorAssertionResponse.signature
//        userHandle = authenticatorAssertionResponse.userHandle?.decodedBytes
//    }
//
//    // swiftlint:disable:next function_parameter_count
//    func verify(
//        expectedChallenge: [UInt8],
//        relyingPartyOrigin: String,
//        relyingPartyID: String,
//        requireUserVerification: Bool,
//        credentialPublicKey: [UInt8],
//        credentialCurrentSignCount: UInt32
//    ) throws {
//        try clientData.verify(
//            storedChallenge: expectedChallenge,
//            ceremonyType: .assert,
//            relyingPartyOrigin: relyingPartyOrigin
//        )
//
//        let expectedRelyingPartyIDData = Data(relyingPartyID.utf8)
//        let expectedRelyingPartyIDHash = SHA256.hash(data: expectedRelyingPartyIDData)
//        guard expectedRelyingPartyIDHash == authenticatorData.relyingPartyIDHash else {
//            throw WebAuthnError.relyingPartyIDHashDoesNotMatch
//        }
//
//        guard authenticatorData.flags.userPresent else { throw WebAuthnError.userPresentFlagNotSet }
//        if requireUserVerification {
//            guard authenticatorData.flags.userVerified else { throw WebAuthnError.userVerifiedFlagNotSet }
//        }
//
//        if authenticatorData.counter > 0 || credentialCurrentSignCount > 0 {
//            guard authenticatorData.counter > credentialCurrentSignCount else {
//                // This is a signal that the authenticator may be cloned, i.e. at least two copies of the credential
//                // private key may exist and are being used in parallel.
//                throw WebAuthnError.potentialReplayAttack
//            }
//        }
//
//        let clientDataHash = SHA256.hash(data: rawClientData)
//        let signatureBase = rawAuthenticatorData + clientDataHash
//
//        let credentialPublicKey = try CredentialPublicKey(publicKeyBytes: credentialPublicKey)
//        guard let signatureData = signature.urlDecoded.decoded else { throw WebAuthnError.invalidSignature }
//        try credentialPublicKey.verify(signature: signatureData, data: signatureBase)
//    }
//}
