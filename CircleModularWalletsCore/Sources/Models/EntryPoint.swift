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

/// Enum class representing entry points with their respective addresses.
///
/// ``https://github.com/pimlicolabs/permissionless.js/blob/fb3c71cb38af576d9e0d6d131472ce941b358c9c/packages/permissionless/types/entrypoint.ts#L4``
public enum EntryPoint: Sendable {

    /// Represents the entry point version 0.7 with its respective address.
    case v07
    
    /// The address of the entry point.
    public var address: String {
        switch self {
        case .v07: ENTRYPOINT_V07_ADDRESS
        }
    }
}
