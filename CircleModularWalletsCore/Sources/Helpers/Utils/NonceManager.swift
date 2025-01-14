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

struct FunctionParameters {
    let address: String
    let chainId: Int
}

protocol NonceManagerSource {
    func get(parameters: FunctionParameters) -> BigInt
    func set(parameters: FunctionParameters, nonce: BigInt)
}

struct NonceManagerSourceImpl: NonceManagerSource {
    func get(parameters: FunctionParameters) -> BigInt {
        return BigInt(Date().timeIntervalSince1970 * 1000)
    }

    func set(parameters: FunctionParameters, nonce: BigInt) {
    }
}

class NonceManager: @unchecked Sendable {
    private let source: NonceManagerSource
    private var deltaMap: [String: BigInt] = [:]
    private var nonceMap: [String: BigInt] = [:]

    init(source: NonceManagerSource) {
        self.source = source
    }

    private func getKey(params: FunctionParameters) -> String {
        return "\(params.address).\(params.chainId)"
    }

    ///
    /// Increase delta
    /// Update nonceMap with value (source nonce or previousNonce + 1) + delta.
    /// The value will be used as previousNonce next time.
    ///
    func consume(params: FunctionParameters) -> BigInt {
        let key = getKey(params: params)
        increment(params: params)
        let nonce = get(params: params)
        source.set(parameters: params, nonce: nonce)
        nonceMap[key] = nonce
        return nonce
    }

    /// Increase delta
    private func increment(params: FunctionParameters) {
        let key = getKey(params: params)
        let delta = deltaMap[key] ?? BigInt(0)
        deltaMap[key] = delta + BigInt(1)
    }

    /// Return (source nonce or previousNonce + 1) + delta
    func get(params: FunctionParameters) -> BigInt {
        let key = getKey(params: params)
        let delta = deltaMap[key] ?? BigInt(0)
        let nonce = internalGet(params: params, key: key)
        return delta + nonce
    }

    /// Reset delta
    private func reset(params: FunctionParameters) {
        let key = getKey(params: params)
        deltaMap.removeValue(forKey: key)
    }

    /// Return source nonce or previousNonce + 1
    private func internalGet(params: FunctionParameters, key: String) -> BigInt {
        var nonce: BigInt

        let fetchedNonce = source.get(parameters: params)
        let previousNonce = nonceMap[key] ?? BigInt(0)
        if previousNonce > BigInt(0) && fetchedNonce <= previousNonce {
            nonce = previousNonce + BigInt(1)
        } else {
            nonceMap.removeValue(forKey: key)
            nonce = fetchedNonce
        }

        reset(params: params)

        return nonce
    }
}
