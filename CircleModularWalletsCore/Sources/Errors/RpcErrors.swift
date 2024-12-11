//
// Copyright (c) 2024, Circle Internet Group, Inc. All rights reserved.
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

struct RpcErrorOptions {
    var code: Int? = nil
    var metaMessages: [String]? = nil
    var name: String? = nil
    var shortMessage: String
}

class RpcError: BaseError {
    let code: Int

    init(cause: Error, options: RpcErrorOptions) {
        self.code = options.code ?? -1
        super.init(shortMessage: options.shortMessage,
                   args: .init(
                    cause: cause,
                    metaMessages: RpcError.getMetaMessage(options: options, cause: cause),
                    name: RpcError.getName(options: options, cause: cause)
                   ))
    }
    
    static func getMetaMessage(options: RpcErrorOptions, cause: Error) -> [String]? {
        if let messages = options.metaMessages {
            return messages
        } else if let baseError = cause as? BaseError {
            return baseError.metaMessages
        }
        return nil
    }
    
    static func getName(options: RpcErrorOptions, cause: Error) -> String {
        if let name = options.name {
            return name
        } else if let baseError = cause as? BaseError, baseError.name != "BaseError" {
            return baseError.name
        }
        return "RpcError"
    }
}

class ParseRpcError: RpcError {
    static let code = -32700

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: ParseRpcError.code,
            name: "ParseRpcError",
            shortMessage: "Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text."
        ))
    }
}

class InvalidRequestRpcError: RpcError {
    static let code = -32600

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: InvalidRequestRpcError.code,
            name: "InvalidRequestRpcError",
            shortMessage: "JSON is not a valid request object."
        ))
    }
}

class MethodNotFoundRpcError: RpcError {
    static let code = -32601

    init(cause: Error, method: String? = nil) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: MethodNotFoundRpcError.code,
            name: "MethodNotFoundRpcError",
            shortMessage: "The method\(method != nil ? " \"\(method!)\"" : "") does not exist / is not available."
        ))
    }
}

class InvalidParamsRpcError: RpcError {
    static let code = -32602

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: InvalidParamsRpcError.code,
            name: "InvalidParamsRpcError",
            shortMessage: "Invalid parameters were provided to the RPC method.\nDouble check you have provided the correct parameters."
        ))
    }
}

class InternalRpcError: RpcError {
    static let code = -32603

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: InternalRpcError.code,
            name: "InternalRpcError",
            shortMessage: "An internal error was received."
        ))
    }
}

class InvalidInputRpcError: RpcError {
    static let code = -32000

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: InvalidInputRpcError.code,
            name: "InvalidInputRpcError",
            shortMessage: "Missing or invalid parameters.\nDouble check you have provided the correct parameters."
        ))
    }
}

class ResourceNotFoundRpcError: RpcError {
    static let code = -32001

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: ResourceNotFoundRpcError.code,
            name: "ResourceNotFoundRpcError",
            shortMessage: "Requested resource not found."
        ))
    }
}

class ResourceUnavailableRpcError: RpcError {
    static let code = -32002

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: ResourceUnavailableRpcError.code,
            name: "ResourceUnavailableRpcError",
            shortMessage: "Requested resource not available."
        ))
    }
}

class TransactionRejectedRpcError: RpcError {
    static let code = -32003

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: TransactionRejectedRpcError.code,
            name: "TransactionRejectedRpcError",
            shortMessage: "Transaction creation failed."
        ))
    }
}

class MethodNotSupportedRpcError: RpcError {
    static let code = -32004

    init(cause: Error, method: String? = nil) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: MethodNotSupportedRpcError.code,
            name: "MethodNotSupportedRpcError",
            shortMessage: "Method\(method != nil ? " \"\(method!)\"" : "") is not implemented."
        ))
    }
}

class LimitExceededRpcError: RpcError {
    static let code = -32005

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: LimitExceededRpcError.code,
            name: "LimitExceededRpcError",
            shortMessage: "Request exceeds defined limit."
        ))
    }
}

class JsonRpcVersionUnsupportedError: RpcError {
    static let code = -32006

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: JsonRpcVersionUnsupportedError.code,
            name: "JsonRpcVersionUnsupportedError",
            shortMessage: "Version of JSON-RPC protocol is not supported."
        ))
    }
}

class UnknownRpcError: ProviderRpcError {
    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            name: "UnknownRpcError",
            shortMessage: "An unknown RPC error occurred."
        ))
    }
}

class ProviderRpcError: RpcError {}

class UserRejectedRequestError: ProviderRpcError {
    static let code = 4001

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: UserRejectedRequestError.code,
            name: "UserRejectedRequestError",
            shortMessage: "User rejected the request."
        ))
    }
}

class UnauthorizedProviderError: ProviderRpcError {
    static let code = 4100

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: UnauthorizedProviderError.code,
            name: "UnauthorizedProviderError",
            shortMessage: "The requested method and/or account has not been authorized by the user."
        ))
    }
}

class UnsupportedProviderMethodError: ProviderRpcError {
    static let code = 4200

    init(cause: Error, method: String? = nil) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: UnsupportedProviderMethodError.code,
            name: "UnsupportedProviderMethodError",
            shortMessage: "The Provider does not support the requested method\(method != nil ? " \"\(method!)\"" : "")."
        ))
    }
}

class ProviderDisconnectedError: ProviderRpcError {
    static let code = 4900

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: ProviderDisconnectedError.code,
            name: "ProviderDisconnectedError",
            shortMessage: "The Provider is disconnected from all chains."
        ))
    }
}

class ChainDisconnectedError: ProviderRpcError {
    static let code = 4901

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: ChainDisconnectedError.code,
            name: "ChainDisconnectedError",
            shortMessage: "The Provider is not connected to the requested chain."
        ))
    }
}

class SwitchChainError: ProviderRpcError {
    static let code = 4902

    init(cause: Error) {
        super.init(cause: cause, options: RpcErrorOptions(
            code: SwitchChainError.code,
            name: "SwitchChainError",
            shortMessage: "An error occurred when attempting to switch chain."
        ))
    }
}
