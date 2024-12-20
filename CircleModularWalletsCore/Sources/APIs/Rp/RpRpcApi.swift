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

protocol RpRpcApi {

    static func getRegistrationOptions(
        transport: Transport,
        userName: String
    ) async throws -> PublicKeyCredentialCreationOptions

    static func getRegistrationVerification(
        transport: Transport,
        registrationCredential: RegistrationCredential
    ) async throws -> GetRegistrationVerificationResult

    static func getLoginOptions(
        transport: Transport
    ) async throws -> PublicKeyCredentialRequestOptions

    static func getLoginVerification(
        transport: Transport,
        authenticationCredential: AuthenticationCredential
    ) async throws -> GetLoginVerificationResult
}

extension RpRpcApi {

    static func getRegistrationOptions(
        transport: Transport,
        userName: String
    ) async throws -> PublicKeyCredentialCreationOptions {
        let req = RpcRequest(method: "rp_getRegistrationOptions", params: [userName])
        let response = try await transport.request(req) as RpcResponse<GetRegistrationOptionsResult>
        return response.result
    }

    static func getRegistrationVerification(
        transport: Transport,
        registrationCredential: RegistrationCredential
    ) async throws -> GetRegistrationVerificationResult {
        let req = RpcRequest(method: "rp_getRegistrationVerification", params: [registrationCredential])
        let response = try await transport.request(req) as RpcResponse<GetRegistrationVerificationResult>
        return response.result
    }

    static func getLoginOptions(
        transport: Transport
    ) async throws -> PublicKeyCredentialRequestOptions {
        let req = RpcRequest(method: "rp_getLoginOptions", params: emptyParams)
        let response = try await transport.request(req) as RpcResponse<GetLoginOptionsResult>
        return response.result
    }

    static func getLoginVerification(
        transport: Transport,
        authenticationCredential: AuthenticationCredential
    ) async throws -> GetLoginVerificationResult {
        let req = RpcRequest(method: "rp_getLoginVerification", params: [authenticationCredential])
        let response = try await transport.request(req) as RpcResponse<GetLoginVerificationResult>
        return response.result
    }
}
