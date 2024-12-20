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
import Web3Core

enum UnitUtilsError: Error {
    case invalidValueString
    case negativeValueNotSupported
    case invalidDigitLength
}

struct UnitUtils {
    
    /// Parse positive Gwei value to Wei value
    /// - Parameter value: Gwei value
    /// - Returns: Wei value (negative values will throw error)
    static func parseGweiToWei(_ value: String) throws -> BigInt {
        guard let wei = Utilities.parseToBigUInt(value, units: .gwei) else {
            guard let num = Double(value) else {
                throw UnitUtilsError.invalidValueString
            }
            switch num {
            case ..<0:
                throw UnitUtilsError.negativeValueNotSupported
            default:
                throw UnitUtilsError.invalidDigitLength
            }
        }
        return BigInt(wei)
    }

    /// Parse positive Ether value to Wei value
    /// - Parameter value: Ether value
    /// - Returns: Wei value (negative values will throw error)
    static func parseEtherToWei(_ value: String) throws -> BigInt {
        guard let wei = Utilities.parseToBigUInt(value, units: .ether) else {
            guard let num = Double(value) else {
                throw UnitUtilsError.invalidValueString
            }
            switch num {
            case ..<0:
                throw UnitUtilsError.negativeValueNotSupported
            default:
                throw UnitUtilsError.invalidDigitLength
            }
        }
        return BigInt(wei)
    }
}
