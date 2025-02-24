//
//  Copyright (c) 2025, Circle Internet Group, Inc. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import BigInt

struct FunctionParameters: Hashable {
    let address: String
    let chainId: Int
}

///
/// - Note: Since cross-actor boundary handling is required, BigInt is converted into a string type,
/// as this type is Sendable and can be safely passed across actors.
///
protocol NonceManagerSource: Actor {
    func get(parameters: FunctionParameters) async -> String
    func set(parameters: FunctionParameters, nonce: String) async
}

actor NonceManagerSourceImpl: NonceManagerSource {
    func get(parameters: FunctionParameters) async -> String {
        return BigInt(Date().timeIntervalSince1970 * 1000).description
    }

    func set(parameters: FunctionParameters, nonce: String) async {
    }
}

actor NonceManager {
    private let source: NonceManagerSource
    private var deltaMap: [FunctionParameters: BigInt] = [:]
    private var nonceMap: [FunctionParameters: BigInt] = [:]

    init(source: NonceManagerSource) {
        self.source = source
    }

    ///
    /// Increase delta
    /// Update nonceMap with value (source nonce or previousNonce + 1) + delta.
    /// The value will be used as previousNonce next time.
    ///
    /// - Note: Since cross-actor boundary handling is required, BigInt is converted into a string type,
    /// as this type is Sendable and can be safely passed across actors.
    ///
    @Sendable
    func consume(params: FunctionParameters) async -> String {
        let nonce = await getAndIncrementNonce(params: params)
        await source.set(parameters: params, nonce: nonce.description)
        return nonce.description
    }

    /// Handle nonce reading & modification in a single operation.
    private func getAndIncrementNonce(params: FunctionParameters) async -> BigInt {
        let nextNonce = await internalGet(params: params)

        let delta = deltaMap[params, default: 0]
        deltaMap[params] = delta + BigInt(1)
        nonceMap[params] = nextNonce + delta + BigInt(1)

        let newNonce = nextNonce + deltaMap[params, default: 0]
        deltaMap.removeValue(forKey: params)

        return newNonce
    }

    /// Return (source nonce or previousNonce + 1) + delta
    ///
    /// - Note: Since cross-actor boundary handling is required, BigInt is converted into a string type,
    /// as this type is Sendable and can be safely passed across actors.
    @Sendable
    func get(params: FunctionParameters) async -> String {
        let delta = deltaMap[params, default: 0]
        let nonce = await internalGet(params: params)
        return (delta + nonce).description
    }

    /// Return source nonce or previousNonce + 1
    private func internalGet(params: FunctionParameters) async -> BigInt {
        let fetchedNonceString = await source.get(parameters: params)
        let fetchedNonce = BigInt(fetchedNonceString) ?? BigInt(0)
        let previousNonce = nonceMap[params, default: 0]

        let nonce: BigInt
        if previousNonce > BigInt(0) && fetchedNonce <= previousNonce {
            nonce = previousNonce + BigInt(1)
        } else {
            nonceMap.removeValue(forKey: params)
            nonce = fetchedNonce
        }

        deltaMap.removeValue(forKey: params)

        return nonce
    }
}
