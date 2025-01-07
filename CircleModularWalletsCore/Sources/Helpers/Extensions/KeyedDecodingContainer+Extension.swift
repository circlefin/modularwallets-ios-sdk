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
import BigInt

extension KeyedDecodingContainer {

    func decodeToBigInt(forKey key: KeyedDecodingContainer<K>.Key) throws -> BigInt? {
        let hexString = try? self.decodeIfPresent(String.self, forKey: key)
        return HexUtils.hexToBigInt(hex: hexString)
    }

//    func decodeBytesFromURLEncodedBase64(forKey key: KeyedDecodingContainer.Key) throws -> [UInt8] {
//        guard let bytes = try decode(
//            URLEncodedBase64.self,
//            forKey: key
//        ).decodedBytes else {
//            throw DecodingError.dataCorruptedError(
//                forKey: key,
//                in: self,
//                debugDescription: "Failed to decode base64url encoded string at \(key) into bytes"
//            )
//        }
//        return bytes
//    }

//    func decodeBytesFromURLEncodedBase64IfPresent(forKey key: KeyedDecodingContainer.Key) throws -> [UInt8]? {
//        guard let bytes = try decodeIfPresent(
//            URLEncodedBase64.self,
//            forKey: key
//        ) else { return nil }
//
//        guard let decodedBytes = bytes.decodedBytes else {
//            throw DecodingError.dataCorruptedError(
//                forKey: key,
//                in: self,
//                debugDescription: "Failed to decode base64url encoded string at \(key) into bytes"
//            )
//        }
//        return decodedBytes
//    }
}
