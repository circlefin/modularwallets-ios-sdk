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

extension String {

    var noHexPrefix: String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        let hex = trimmed.hasPrefix("0x") ? String(trimmed.dropFirst(2)) : trimmed
        return hex
    }
}

extension StringProtocol {

//    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
//        range(of: string, options: options)?.lowerBound
//    }

    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Int? {
        guard let endIndex = range(of: string, options: options)?.lowerBound else {
            return nil
        }

        return self.distance(from: self.startIndex, to: endIndex)
    }

//    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
//        range(of: string, options: options)?.upperBound
//    }

//    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Int? {
//        guard let endIndex = range(of: string, options: options)?.upperBound else {
//            return nil
//        }
//
//        return self.distance(from: self.startIndex, to: endIndex)
//    }

//    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
//        ranges(of: string, options: options).map(\.lowerBound)
//    }
    
//    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
//        var result: [Range<Index>] = []
//        var startIndex = self.startIndex
//        while startIndex < endIndex,
//            let range = self[startIndex...]
//                .range(of: string, options: options) {
//                result.append(range)
//                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
//                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
//        }
//        return result
//    }
}
