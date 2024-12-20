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

/// COSEAlgorithmIdentifier From §5.10.5. A number identifying a cryptographic algorithm. The algorithm
/// identifiers SHOULD be values registered in the IANA COSE Algorithms registry
/// [https://www.w3.org/TR/webauthn/#biblio-iana-cose-algs-reg], for instance, -7 for "ES256" and -257 for "RS256".
public enum COSEAlgorithmIdentifier: Int, RawRepresentable, CaseIterable, Encodable, Sendable {

    case unknown = 0

    /// AlgES256 ECDSA with SHA-256
	case algES256 = -7
	/// AlgES384 ECDSA with SHA-384
	case algES384 = -35
	/// AlgES512 ECDSA with SHA-512
	case algES512 = -36

	/// AlgRS1 RSASSA-PKCS1-v1_5 with SHA-1
	 case algRS1 = -65535
	/// AlgRS256 RSASSA-PKCS1-v1_5 with SHA-256
	 case algRS256 = -257
	/// AlgRS384 RSASSA-PKCS1-v1_5 with SHA-384
	 case algRS384 = -258
	/// AlgRS512 RSASSA-PKCS1-v1_5 with SHA-512
	 case algRS512 = -259

	/// AlgPS256 RSASSA-PSS with SHA-256
	 case algPS256 = -37
	/// AlgPS384 RSASSA-PSS with SHA-384
	 case algPS384 = -38
	/// AlgPS512 RSASSA-PSS with SHA-512
	 case algPS512 = -39

	// AlgEdDSA EdDSA
	 case algEdDSA = -8
}
