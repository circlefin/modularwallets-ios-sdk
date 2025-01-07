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
import OSLog

typealias logger = Logger

extension Logger {

    private static let appIdentifier = Bundle.main.bundleIdentifier ?? ""

    // Predefined Logger categories
    //
    // The categories align with the Error definitions
    // https://docs.google.com/document/d/1iUQC2UFZcBkB5EFscql1XFojnF0Jir_7KjOYpCGgXEQ/edit?pli=1
    //
    // - Usages:
    //     - logger.main.debug("some debugging messages")
    //     - logger.rpc.error("some error messages in RPC module")
    //
    // - Recommend log level use cases:
    //     - Debug: Useful only during debugging
    //     - Info: Helpful but not essential for troubleshooting
    //     - Default(Notice): Essential for troubleshooting
    //     - Error: Error seen during execution
    //     - Fault: Bug in program

    static let general = Logger(subsystem: appIdentifier, category: "general")
    static let transport = Logger(subsystem: appIdentifier, category: "transport")
    
    static let bundler = Logger(subsystem: appIdentifier, category: "bundler")
    static let paymaster = Logger(subsystem: appIdentifier, category: "paymaster")
    static let utils = Logger(subsystem: appIdentifier, category: "utils")
    static let webAuthn = Logger(subsystem: appIdentifier, category: "WebAuthn")
    static let passkeyAccount = Logger(subsystem: appIdentifier, category: "passkeyAccount")
}

//extension Logger {
//    
//    func divider(level: OSLogType = .debug) {
//        self.log(level: level, "∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞")
//    }
//
//    func prettyPrinted(level: OSLogType = .debug, _ object: Encodable) {
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted
//
//        guard let data = try? encoder.encode(object),
//                let jsonString = String(data: data, encoding: .utf8) else {
//            self.debug("Invalid JSON object")
//            return
//        }
//        self.log(level: level, "\(jsonString)")
//    }
//}
