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

@_documentation(visibility: private)
public class RpcRequestError: BaseError, @unchecked Sendable {
    let code: Int
    
    init(body: Data?, error: JsonRpcError, url: String) {
        self.code = error.code
        super.init(shortMessage: "RPC Request failed.",
                   args: .init(
                    details: error.message,
                    metaMessages: ["URL: \(url)", "Request body: \(prettyPrint(body))"],
                    name: "RpcRequestError"
                   ))
    }
}

@_documentation(visibility: private)
public class HttpRequestError: BaseError, @unchecked Sendable {
    let body: Data?
    let headers: [String: String]?
    let status: Int?
    
    init(body: Data? = nil,
         cause: Error? = nil,
         details: String? = nil,
         headers: [String: String]? = nil,
         status: Int? = nil,
         url: String) {
        self.body = body
        self.headers = headers
        self.status = status
        super.init(shortMessage: "HTTP request failed.",
                   args: .init(
                    cause: cause,
                    details: details,
                    metaMessages: HttpRequestError.getMetaMessage(status: status,
                                                                  url: url,
                                                                  headers: headers,
                                                                  body: body),
                    name: "HttpRequestError"
                   ))
    }
    
    static func getMetaMessage(status: Int?,
                               url: String,
                               headers: [String: String]?,
                               body: Data?) -> [String] {
        var result = [String]()
        if let status {
            result.append("Status: \(status)")
        }
        result.append("URL: \(url)")
        if let headers {
            result.append("Request headers: \(prettyPrint(headers))")
        }
        if let body {
            result.append("Request body: \(prettyPrint(body))")
        }
        return result
    }
}

@_documentation(visibility: private)
public class TimeoutError: BaseError, @unchecked Sendable {
    init(body: Data?, url: String) {
        var metaMessages: [String] = []
        metaMessages.append("URL: \(url)")
        if let body {
            metaMessages.append("Request body: \(prettyPrint(body))")
        }
        super.init(shortMessage: "The request took too long to respond.",
                   args: .init(
                    details: "The request timed out.",
                    metaMessages: metaMessages,
                    name: "TimeoutError"
                   ))
    }
}
