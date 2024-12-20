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

struct WebAuthnUtils {

    static func getRequestOption(
        rpId: String,
        allowCredentialId: String? = nil,
        hex: String
    ) throws -> PublicKeyCredentialRequestOptions {
        guard let challengeData = HexUtils.hexToData(hex: hex) else {
            throw BaseError(shortMessage: "Failed to get requestOption, hexToData(hex: \"\(hex)\") conversion failure")
        }

        let challenge = challengeData.base64URLEncodedString()
        var allowCredentials: [PublicKeyCredentialDescriptor]? = nil
        if let allowCredentialId {
            allowCredentials = [PublicKeyCredentialDescriptor(id: allowCredentialId)]
        }

        let option = PublicKeyCredentialRequestOptions(
            challenge: challenge,
            relyingParty: .init(id: rpId, name: rpId),
            allowCredentials: allowCredentials,
            userVerification: .required
        )

        return option
    }
}
