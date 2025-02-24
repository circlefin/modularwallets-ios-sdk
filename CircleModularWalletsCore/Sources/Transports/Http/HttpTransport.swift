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

/// The http Transport connects to a JSON-RPC API via HTTP.
public class HttpTransport: Transport {

    let session: URLSession
    let url: String
    let options: HttpRpcClientOptions?

    init(url: String, options: HttpRpcClientOptions? = nil) {
        self.session = URLSession.shared
        self.url = url
        self.options = options
    }

    public func request<P, R>(_ rpcRequest: RpcRequest<P>) async throws -> RpcResponse<R> where P: Encodable, R: Decodable {
        do {
            let urlRequest = try toUrlRequest(rpcRequest, urlString: self.url)
            return try await send(urlRequest)

        } catch let error as BaseError {
            throw error

        } catch {
            throw BaseError(shortMessage: error.localizedDescription,
                            args: .init(cause: error, name: String(describing: error)))
        }
    }
}

extension HttpTransport {

    func send<T: Decodable>(_ urlRequest: URLRequest) async throws -> T {
        var data: Data = .init(), response: URLResponse?
        do {
            (data, response) = try await session.data(for: urlRequest)
            try processResponse(data: data, response: response)

            if let errorResult = try? decodeData(data: data) as JsonRpcErrorResult {
                let rpcRequstError = RpcRequestError(body: urlRequest.httpBody,
                                                     error: errorResult.error,
                                                     url: url)
                let rpcError = ErrorUtils.getRpcError(cause: rpcRequstError)
                throw rpcError
            } else {
                return try decodeData(data: data) as T
            }

        } catch let error as BaseError {
            throw error
        } catch let error as HttpError {
            var _details: String?
            var _cause: Error?
            var _statusCode: Int?

            switch error {
            case .encodingFailed(let error):
                _details = "Encoding Failed."
                _cause = error
            case .decodingFailed(let error):
                _details = "Decoding Failed."
                _cause = error
            case .unknownError(let statusCode):
                if let errorResult = try? decodeData(data: data) as JsonRpcErrorResult {
                    _details = errorResult.error.message
                } else {
                    let message = String(data: data, encoding: .utf8) ?? ""
                    _details = "Request failed: \(message)"
                }
                _statusCode = statusCode
            default:
                _details = String(describing: error)
            }
            throw HttpRequestError(body: urlRequest.httpBody,
                                   cause: _cause,
                                   details: _details,
                                   headers: urlRequest.allHTTPHeaderFields,
                                   status: _statusCode,
                                   url: urlRequest.url?.absoluteString ?? url)

        } catch {
            throw HttpRequestError(body: urlRequest.httpBody,
                                   cause: error,
                                   details: "Http request failed.",
                                   headers: urlRequest.allHTTPHeaderFields,
                                   url: urlRequest.url?.absoluteString ?? url)
        }
    }

    func toUrlRequest(_ request: Encodable, urlString: String) throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw HttpError.badURL
        }

        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let appInfos = ["platform=ios",
                        "version=\(Bundle.SDK.version)",
                        "bundleid=\(Bundle.main.identifier)"]
        req.addValue(appInfos.joined(separator: ";"), forHTTPHeaderField: "X-AppInfo")

        options?.headers.forEach { key, value in
            req.addValue(value, forHTTPHeaderField: key)
        }

        do {
            req.httpBody = try JSONEncoder().encode(request)
        } catch let encodingError {
            throw HttpError.encodingFailed(encodingError)
        }
        return req
    }

    func processResponse(data: Data, response: URLResponse?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            break
        default: throw
            HttpError.unknownError(statusCode: httpResponse.statusCode)
        }
    }

    func decodeData<T: Decodable>(data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)

        } catch let decodingError {
            if !(T.self is JsonRpcErrorResult.Type) {
                let dataString = String(data: data, encoding: .utf8)
                logger.transport.error("[DecodingError] \(T.self) from content: \(dataString ?? "{}")")
            }
            throw HttpError.decodingFailed(decodingError)
        }
    }
}
