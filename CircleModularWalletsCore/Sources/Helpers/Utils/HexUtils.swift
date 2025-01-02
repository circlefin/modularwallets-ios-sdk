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

enum HexConversionError: Error {
    case invalidDigit
    case stringNotEven
}

struct HexUtils {

    static func intToHex(_ int: Int?, withPrefix: Bool = true) -> String {
        guard let int else { return withPrefix ? "0x" : "" }
        let hexString = String(format: "%x", int)
        return withPrefix ? "0x" + hexString : hexString
    }

    static func dataToHex(_ data: Data?, withPrefix: Bool = true) -> String {
        guard let data else { return withPrefix ? "0x" : "" }
        let hexString = data.map { String(format: "%02hhx", $0) }.joined()
        return withPrefix ? "0x" + hexString : hexString
    }

    static func bytesToHex(_ bytes: [UInt8]?, withPrefix: Bool = true) -> String {
        guard let bytes else { return withPrefix ? "0x" : "" }
        let hexString = bytes.map { String(format: "%02hhx", $0) }.joined()
        return withPrefix ? "0x" + hexString : hexString
    }

    static func hexToInt(hex: String?) -> Int? {
        guard let hex else { return nil }
        return Int(hex.noHexPrefix, radix: 16)
    }

    static func hexToBigInt(hex: String?) -> BigInt? {
        guard let hex else { return nil }
        return BigInt(hex.noHexPrefix, radix: 16)
    }

    static func bigIntToHex(_ bigInt: BigInt, withPrefix: Bool = true) throws -> String {
        if bigInt.sign == .minus {
            throw IntegerOutOfRangeError()
        }
        let hex = BigUInt(bigInt).hexString
        return withPrefix ? hex : hex.noHexPrefix
    }

    static func hexToData(hex: String?) -> Data? {
        guard let hex else { return nil }
        guard let bytes = try? HexUtils.hexToBytes(hex: hex.noHexPrefix) else {
            return nil
        }

        return Data(bytes)
    }

    static func hexToBytes(hex string: String) throws -> [UInt8] {
        var iterator = string.noHexPrefix.unicodeScalars.makeIterator()
        var byteArray: [UInt8] = []

        while let msn = iterator.next() {
            if let lsn = iterator.next() {
                do {
                    let convertedMsn = try convert(hexDigit: msn)
                    let convertedLsn = try convert(hexDigit: lsn)
                    byteArray += [convertedMsn << 4 | convertedLsn]
                } catch {
                    throw error
                }
            } else {
                throw HexConversionError.stringNotEven
            }
        }
        return byteArray
    }

    private static func convert(hexDigit digit: UnicodeScalar) throws -> UInt8 {
        switch digit {
        case UnicodeScalar(unicodeScalarLiteral: "0") ... UnicodeScalar(unicodeScalarLiteral: "9"):
            return UInt8(digit.value - UnicodeScalar(unicodeScalarLiteral: "0").value)

        case UnicodeScalar(unicodeScalarLiteral: "a") ... UnicodeScalar(unicodeScalarLiteral: "f"):
            return UInt8(digit.value - UnicodeScalar(unicodeScalarLiteral: "a").value + 0xa)

        case UnicodeScalar(unicodeScalarLiteral: "A") ... UnicodeScalar(unicodeScalarLiteral: "F"):
            return UInt8(digit.value - UnicodeScalar(unicodeScalarLiteral: "A").value + 0xa)

        default:
            throw HexConversionError.invalidDigit
        }
    }
}
