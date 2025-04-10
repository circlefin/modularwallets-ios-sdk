// swift-tools-version: 5.7
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

import PackageDescription

let package = Package(
    name: "CircleModularWalletsCore",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "CircleModularWalletsCore",
            targets: ["CircleModularWalletsCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/valpackett/SwiftCBOR.git", .upToNextMinor(from: "0.4.7")),
        .package(url: "https://github.com/web3swift-team/web3swift.git", .upToNextMinor(from: "3.2.2"))
    ],
    targets: [
        .target(
            name: "CircleModularWalletsCore",
            dependencies: [
                "web3swift",
                "SwiftCBOR"
            ],
            path: "CircleModularWalletsCore/Sources",
            resources: [
                .copy("../Resources/PrivacyInfo.xcprivacy")
            ],
            cSettings: [
                .define("BUILD_LIBRARY_FOR_DISTRIBUTION", to: "YES")
            ]
        )
    ],
    swiftLanguageVersions: [.version("6"), .v5]
)
