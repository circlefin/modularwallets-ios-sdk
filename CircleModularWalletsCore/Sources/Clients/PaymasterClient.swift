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

/// A Paymaster Client is an interface to interact with ERC-7677 compliant Paymasters and provides the ability to sponsor User Operation gas fees.
public class PaymasterClient: Client, PaymasterRpcApi {

    /// Retrieves Paymaster data for a given User Operation.
    ///
    /// - Parameters:
    ///   - userOp: The User Operation to retrieve Paymaster data for. Type `T` must be a subclass of `UserOperation`.
    ///   - entryPoint: The EntryPoint address to target.
    ///   - context: Paymaster-specific fields (optional).
    ///
    /// - Returns: Paymaster-related User Operation properties.
    public func getPaymasterData<T: UserOperation>(
        userOp: T,
        entryPoint: EntryPoint,
        context: [String: AnyEncodable]? = nil
    ) async throws -> GetPaymasterDataResult {
        try await self.getPaymasterData(transport: transport, userOp: userOp, entryPoint: entryPoint, chainId: chain.chainId, context: context)
    }

    /// Retrieves Paymaster stub data for a given User Operation.
    ///
    /// - Parameters:
    ///   - userOp: The User Operation to retrieve Paymaster stub data for. Type `T` must be a subclass of `UserOperation`.
    ///   - entryPoint: The EntryPoint address to target.
    ///   - context: Paymaster-specific fields (optional).
    ///
    /// - Returns: Paymaster-related User Operation properties.
    public func getPaymasterStubData<T: UserOperation>(
        userOp: T,
        entryPoint: EntryPoint,
        context: [String: AnyEncodable]? = nil
    ) async throws -> GetPaymasterStubDataResult {
        try await self.getPaymasterStubData(transport: transport, userOp: userOp, entryPoint: entryPoint, chainId: chain.chainId, context: context)
    }

}
