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

struct BaseErrorParameters {
    var cause: Error? = nil
    var details: String? = nil
    var metaMessages: [String]? = nil
    var name: String = "BaseError"
}

@_documentation(visibility: private)
public class BaseError: Error, CustomStringConvertible, @unchecked Sendable {

    public let shortMessage: String
    public let details: String?
    public let metaMessages: [String]?
    public let name: String

    public private(set) var description: String = ""
    public let cause: Error?

    init(shortMessage: String, args: BaseErrorParameters = BaseErrorParameters()) {
        self.shortMessage = shortMessage
        self.details = BaseError.getDetails(args: args)
        self.metaMessages = args.metaMessages
        self.name = args.name

        self.description = BaseError.buildMessage(shortMessage: shortMessage, args: args)
        self.cause = args.cause
    }

    static func getDetails(args: BaseErrorParameters) -> String? {
        if args.cause == nil {
            return args.details
        } else if let cause = args.cause as? BaseError {
            return cause.details
        } else {
            return args.cause?.localizedDescription
        }
    }

    static func buildMessage(shortMessage: String, args: BaseErrorParameters) -> String {
        var messageParts: [String] = []
        messageParts.append("\(args.name): \(shortMessage.isEmpty ? "An error occurred." : shortMessage)")

        if let messageLastPart = messageParts.last,  !messageLastPart.hasSuffix("\n") {
            messageParts[messageParts.count - 1] += "\n"
        }

        if let metaMessages = args.metaMessages {
            messageParts.append(contentsOf: metaMessages)
        }

        if let messageLastPart = messageParts.last,  !messageLastPart.hasSuffix("\n") {
            messageParts[messageParts.count - 1] += "\n"
        }

        if let details = getDetails(args: args) {
            messageParts.append("Details: \(details)")
        }

        messageParts.append("Version: \(Bundle.SDK.version)")

        return messageParts.joined(separator: "\n")
    }

    public func walk(fn: ((Error?) -> Bool)? = nil) -> Error? {
        return BaseError.walk(err: self, fn: fn)
    }

    static func walk(err: Error? = nil, fn: ((Error?) -> Bool)? = nil) -> Error? {
        if let fn = fn, fn(err) {
            return err
        }
        if let cause = (err as? BaseError)?.cause {
            return walk(err: cause, fn: fn)
        }
        return fn == nil ? err : nil
    }
}
