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

@_documentation(visibility: private)// https://github.com/wevm/viem/blob/3866a6faeb9e64ba3da6063fe78a079ea53c2c5f/src/account-abstraction/errors/userOperation.ts#L104
public class WaitForUserOperationReceiptTimeoutError: BaseError, @unchecked Sendable {
    init(hash: String) {
        super.init(shortMessage: "Timed out while waiting for User Operation with hash \"\(hash)\" to be confirmed.",
                   args: .init(name: "WaitForUserOperationReceiptTimeoutError"))
    }
}

@_documentation(visibility: private)// https://github.com/wevm/viem/blob/3866a6faeb9e64ba3da6063fe78a079ea53c2c5f/src/account-abstraction/errors/userOperation.ts#L80
public class UserOperationReceiptNotFoundError: BaseError, @unchecked Sendable {
    init(hash: String, cause: Error?) {
        super.init(shortMessage: "User Operation receipt with hash \"\(hash)\" could not be found. The User Operation may not have been processed yet.",
                   args: .init(cause: cause, name: "UserOperationReceiptNotFoundError"))
    }
}

@_documentation(visibility: private)//https://github.com/wevm/viem/blob/f34580367127be8ec02e2f1a9dbf5d81c29e74e8/src/account-abstraction/errors/userOperation.ts#L89C1-L99C1
public class UserOperationNotFoundError: BaseError, @unchecked Sendable {
    init(hash: String) {
        super.init(shortMessage: "User Operation with hash \"\(hash)\" could not be found.",
                   args: .init(name: "UserOperationNotFoundError"))
    }
}

@_documentation(visibility: private)
public class UserOperationExecutionError: BaseError, @unchecked Sendable {
    private init(cause: BaseError, parameters: BaseErrorParameters) {
        super.init(shortMessage: cause.shortMessage, args: parameters)
    }
    
    convenience init(cause: BaseError, userOp: UserOperation) {
        let prettyArgs = prettyPrint(userOp)
        let params = BaseErrorParameters(
            cause: cause,
            metaMessages: UserOperationExecutionError.getMetaMessages(cause: cause, prettyArgs: prettyArgs),
            name: "UserOperationExecutionError"
        )
        self.init(cause: cause, parameters: params)
    }
    
    static func getMetaMessages(cause: BaseError, prettyArgs: String) -> [String] {
        var messages: [String] = cause.metaMessages ?? []
        
        if !messages.isEmpty, let last = messages.last, !(last.hasSuffix("\n")) {
            messages[messages.count - 1] += "\n"
        }
        
        messages.append("Request Arguments:")
        messages.append(prettyArgs)
        
        return messages.filter { !$0.isEmpty }
    }
}
