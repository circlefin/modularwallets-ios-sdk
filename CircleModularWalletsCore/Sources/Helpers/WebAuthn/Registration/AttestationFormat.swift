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

public enum AttestationFormat: Equatable, Sendable {
    case apple
    case none
    case custom(String)

    public var rawValue: String {
        switch self {
        case .apple: return "apple"
        case .none: return "none"
        case .custom(let value): return value
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "apple": self = .apple
        case "none": self = .none
        default: self = .custom(rawValue)
        }
    }
}
