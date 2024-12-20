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
import BigInt
import Web3Core

enum FeeValuesType {
    case eip1559
    case legacy
}

protocol PublicRpcApi {

    /// Returns the balance of an address in wei.
    func getBalance(transport: Transport,
                    address: String,
                    blockNumber: BlockNumber) async throws -> BigInt

    /// Returns the number of the most recent block seen.
    func getBlockNum(transport: Transport) async throws -> BigInt

    /// Returns information about a block at a block number (hex) or tag.
    func getBlock(transport: Transport,
                  includeTransactions: Bool,
                  blockNumber: BlockNumber) async throws -> Block

    /// Returns the chain ID associated with the current network.
    func _getChainId(transport: Transport) async throws -> String

    /// Executes a new message call immediately without submitting a transaction to the network.
    func ethCall(transport: Transport,
                 transaction: CodableTransaction,
                 blockNumber: BlockNumber) async throws -> String

    ///  Retrieves the bytecode at an address.
    func getCode(transport: Transport,
                 address: String,
                 blockNumber: BlockNumber) async throws -> String

    /// - Parameter transport: Estimate fee per gas for EIP-1159
    /// - Returns: EstimateFeesPerGasResult
    func estimateFeesPerGas(transport: Transport, feeValuesType: FeeValuesType) async throws -> EstimateFeesPerGasResult

    /// Returns the current price of gas (in wei)
    func getGasPrice(transport: Transport) async throws -> BigInt
}

extension PublicRpcApi {

    func getBalance(transport: Transport,
                    address: String,
                    blockNumber: BlockNumber = .latest) async throws -> BigInt {
        let params = [address,                     blockNumber.description]
        let req = RpcRequest(method: "eth_getBalance", params: params)
        let response = try await transport.request(req) as RpcResponse<String>

        guard let bigInt = HexUtils.hexToBigInt(hex: response.result) else {
            throw BaseError(shortMessage: "Failed to transform to BigInt")
        }

        return bigInt
    }

    func getBlockNum(transport: Transport) async throws -> BigInt {
        let req = RpcRequest(method: "eth_blockNumber", params: emptyParams)
        let response = try await transport.request(req) as RpcResponse<String>

        guard let bigInt = HexUtils.hexToBigInt(hex: response.result) else {
            throw BaseError(shortMessage: "Failed to transform to BigInt")
        }

        return bigInt
    }

    func getBlock(transport: Transport,
                  includeTransactions: Bool = false,
                  blockNumber: BlockNumber = .latest) async throws -> Block {
        let params: [AnyEncodable] = [AnyEncodable(blockNumber.description),
                                      AnyEncodable(includeTransactions)]
        let req = RpcRequest(method: "eth_getBlockByNumber", params: params)
        let response = try await transport.request(req) as RpcResponse<Block>
        return response.result
    }

    func _getChainId(transport: Transport) async throws -> String {
        let req = RpcRequest(method: "eth_chainId", params: emptyParams)
        let response = try await transport.request(req) as RpcResponse<String>
        return response.result
    }

    func ethCall(transport: Transport,
                 transaction: CodableTransaction,
                 blockNumber: BlockNumber = .latest) async throws -> String {
        let params = EthCallParams(
            from: transaction.from?.address,
            to: transaction.to.address,
            data: HexUtils.dataToHex(transaction.data),
            block: blockNumber.description
        )
        let req = RpcRequest(method: "eth_call", params: params)
        let response = try await transport.request(req) as RpcResponse<String>
        return response.result
    }

    func getCode(transport: Transport,
                 address: String,
                 blockNumber: BlockNumber = .latest) async throws -> String {
        let params = [address, blockNumber.description]
        let req = RpcRequest(method: "eth_getCode", params: params)
        let response = try await transport.request(req) as RpcResponse<String>
        return response.result
    }

    func estimateFeesPerGas(transport: Transport,
                            feeValuesType: FeeValuesType = .eip1559) async throws -> EstimateFeesPerGasResult {
        do {
            let baseFeeMultiplier = 1.2
            let block = try await getBlock(transport: transport)

            switch feeValuesType {
            case .eip1559:
                guard let baseFeePerGas = block.baseFeePerGas else {
                    throw BaseError(shortMessage: "Eip1559FeesNotSupportedError")
                }
                let maxPriorityFeePerGas = try await estimateMaxPriorityFeePerGas(transport: transport,
                                                                                  block: block)
                let newBaseFeePerGas = BigInt(baseFeePerGas) * BigInt(baseFeeMultiplier)
                let maxFeePerGas = newBaseFeePerGas + maxPriorityFeePerGas
                return EstimateFeesPerGasResult(maxFeePerGas: maxFeePerGas,
                                                maxPriorityFeePerGas: maxPriorityFeePerGas,
                                                gasPrice: nil)
            case .legacy:
                let gasPrice = try await getGasPrice(transport: transport)
                return EstimateFeesPerGasResult(maxFeePerGas: nil,
                                                maxPriorityFeePerGas: nil,
                                                gasPrice: gasPrice)
            }

        } catch let error as BaseError {
            throw error

        } catch {
            throw BaseError(shortMessage: error.localizedDescription,
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    func getGasPrice(transport: Transport) async throws -> BigInt {
        let req = RpcRequest(method: "eth_gasPrice", params: emptyParams)
        let response = try await transport.request(req) as RpcResponse<String>

        if let result = HexUtils.hexToBigInt(hex: response.result) {
            return result
        } else {
            throw CommonError.invalidHexString
        }
    }
}

extension PublicRpcApi {

    func estimateMaxPriorityFeePerGas(transport: Transport,
                                      block: Block) async throws -> BigInt {
        do {
            return try await getMaxPriorityFeePerGas(transport: transport)
        } catch {
            return try await estimateMaxPriorityFeePerGasFallback(transport: transport,
                                                                  block: block)
        }
    }
    
    func getMaxPriorityFeePerGas(transport: Transport) async throws -> BigInt {
        let req = RpcRequest(method: "eth_maxPriorityFeePerGas", params: emptyParams)
        let response = try await transport.request(req) as RpcResponse<String>
        
        if let result = HexUtils.hexToBigInt(hex: response.result) {
            return result
        } else {
            throw CommonError.invalidHexString
        }
    }
    
    func estimateMaxPriorityFeePerGasFallback(transport: Transport,
                                              block: Block) async throws -> BigInt {
        guard let baseFeePerGas = block.baseFeePerGas else {
            throw BaseError(shortMessage: "Eip1559FeesNotSupportedError")
        }
        let gasPrice = try await getGasPrice(transport: transport)
        let maxPriorityFeePerGas = gasPrice - BigInt(baseFeePerGas)
        return max(maxPriorityFeePerGas, .zero)
    }
}
