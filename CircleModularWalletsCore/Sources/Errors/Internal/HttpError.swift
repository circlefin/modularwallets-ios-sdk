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

/// This enum lists possible network-related errors that might occur, making error handling more manageable.
enum HttpError: Error {

    /// Indicates an invalid URL.
    case badURL

    /// Indicates a failure in the network request, storing the original error.
    case requestFailed(Error)

    /// Indicates that the response received is not valid.
    case invalidResponse

    /// Indicates that the data expected from the response was not found.
    case dataNotFound

    /// Indicates failure in decoding the response data into the expected type.
    case decodingFailed(Error)

    /// Indicates failure in encoding the request parameters.
    case encodingFailed(Error)

    /// Indicates an unknown error with the associated status code.
    case unknownError(statusCode: Int)

    /// Indicates an JSON-RPC error occurred when execution
    case jsonrpcExecutionError(JsonRpcError)
}
