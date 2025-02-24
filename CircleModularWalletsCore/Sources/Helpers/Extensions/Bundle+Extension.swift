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

#if SWIFT_PACKAGE
extension Bundle {
    public enum SDK {
        public static let version = "1.0.9"
    }
}
#else
extension Bundle {
    static let SDK = Bundle(identifier: "com.circle.ModularWallets.core") ?? Bundle.main
}
#endif

extension Bundle {
    var name: String         { getInfo("CFBundleName") }
    var displayName: String  { getInfo("CFBundleDisplayName") }
    var language: String     { getInfo("CFBundleDevelopmentRegion") }
    var identifier: String   { getInfo("CFBundleIdentifier") }
    var copyright: String    { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }

    var build: String        { getInfo("CFBundleVersion") }
    var version: String      { getInfo("CFBundleShortVersionString") }

    private func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}
