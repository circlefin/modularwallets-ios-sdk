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

func prettyPrint(_ content: Any?) -> String {

    func prettyPrintDictionary(dict: [String: String]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }

    func prettyPrintEncodable(object: Encodable) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(object) else{ return nil }
        return String(data: data, encoding: .utf8)
    }

    if let data = content as? Data {
        return String(data: data, encoding: .utf8) ?? String(describing: data)

    } else if let dict = content as? [String: String] {
        return prettyPrintDictionary(dict: dict) ?? String(describing: dict)

    } else if let object = content as? Encodable {
        return prettyPrintEncodable(object: object) ?? String(describing: object)

    } else {
        return String(describing: content)
    }
}
