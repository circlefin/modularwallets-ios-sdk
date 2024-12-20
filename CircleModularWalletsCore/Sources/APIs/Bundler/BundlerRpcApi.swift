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

protocol BundlerRpcApi: PublicRpcApi, PaymasterRpcApi {

    func estimateUserOperationGas<T: UserOperation>(
        transport: Transport,
        userOp: T,
        entryPoint: EntryPoint
    ) async throws -> EstimateUserOperationGasResult

    func getChainId(transport: Transport) async throws -> Int

    func getSupportedEntryPoints(transport: Transport) async throws -> [String]

    func getUserOperation(transport: Transport, userOpHash: String) async throws -> GetUserOperationResult

    func getUserOperationReceipt(transport: Transport, userOpHash: String) async throws -> GetUserOperationReceiptResult

    func prepareUserOperation(
        transport: Transport,
        account: SmartAccount,
        calls: [EncodeCallDataArg]?,
        partialUserOp: UserOperationV07,
        paymaster: Paymaster?,
        bundlerClient: BundlerClient,
        estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)?
    ) async throws -> UserOperationV07

    func sendUserOperation(
        transport: Transport,
        partialUserOp: UserOperationV07,
        entryPointAddress: String
    ) async throws -> String

    func waitForUserOperationReceipt(
        transport: Transport,
        userOpHash: String,
        pollingInterval: Int,
        retryCount: Int,
        timeout: Int?
    ) async throws -> GetUserOperationReceiptResult
}

extension BundlerRpcApi {

    func estimateUserOperationGas<T: UserOperation>(
        transport: Transport,
        userOp: T,
        entryPoint: EntryPoint
    ) async throws -> EstimateUserOperationGasResult {
        do {
            let params = [AnyEncodable(userOp),
                          AnyEncodable(entryPoint.address)]
            let req = RpcRequest(method: "eth_estimateUserOperationGas", params: params)
            let response = try await transport.request(req) as RpcResponse<EstimateUserOperationGasResult>
            return response.result

        } catch let error as BaseError {
            throw ErrorUtils.getUserOperationExecutionError(err: error, userOp: userOp)

        } catch {
            let baseError = BaseError(shortMessage: error.localizedDescription,
                                      args: .init(cause: error, name: String(describing: error)))
            throw ErrorUtils.getUserOperationExecutionError(err: baseError, userOp: userOp)
        }
    }

    func getChainId(transport: Transport) async throws -> Int {
        let chainIdHex = try await self._getChainId(transport: transport)
        guard let chainId = HexUtils.hexToInt(hex: chainIdHex) else {
            throw CommonError.invalidHexString
        }
        return chainId
    }

    func getSupportedEntryPoints(transport: Transport) async throws -> [String] {
        let req = RpcRequest(method: "eth_supportedEntryPoints", params: emptyParams)
        let response = try await transport.request(req) as RpcResponse<[String]>
        return response.result
    }

    func getUserOperation(transport: Transport, userOpHash: String) async throws -> GetUserOperationResult {
        do {
            let req = RpcRequest(method: "eth_getUserOperationByHash", params: [userOpHash])
            let response = try await transport.request(req) as RpcResponse<GetUserOperationResult>
            return response.result

        } catch {
            throw UserOperationNotFoundError(hash: userOpHash)
        }
    }

    func getUserOperationReceipt(transport: Transport, userOpHash: String) async throws -> GetUserOperationReceiptResult {
        do {
            let req = RpcRequest(method: "eth_getUserOperationReceipt", params: [userOpHash])
            let response = try await transport.request(req) as RpcResponse<GetUserOperationReceiptResult>
            return response.result

        } catch {
            throw UserOperationReceiptNotFoundError(hash: userOpHash, cause: error)
        }
    }

    func prepareUserOperation(
        transport: Transport,
        account: SmartAccount,
        calls: [EncodeCallDataArg]?,
        partialUserOp: UserOperationV07,
        paymaster: Paymaster?,
        bundlerClient: BundlerClient,
        estimateFeesPerGas: ((SmartAccount, BundlerClient, UserOperationV07) async -> EstimateFeesPerGasResult)?
    ) async throws -> UserOperationV07 {
        do {
            if let estimateGas = await account.userOperation?.estimateGas,
               let r = await estimateGas(partialUserOp) {
                partialUserOp.preVerificationGas = r.preVerificationGas ?? partialUserOp.preVerificationGas
                partialUserOp.verificationGasLimit = r.verificationGasLimit ?? partialUserOp.verificationGasLimit
                partialUserOp.callGasLimit = r.callGasLimit ?? partialUserOp.callGasLimit
                partialUserOp.paymasterVerificationGasLimit = r.paymasterVerificationGasLimit ?? partialUserOp.paymasterVerificationGasLimit
                partialUserOp.paymasterPostOpGasLimit = r.paymasterPostOpGasLimit ?? partialUserOp.paymasterPostOpGasLimit
            }

            let userOp = partialUserOp.copy()
            userOp.sender = account.getAddress()

            if let calls = calls {
                let updatedCalls = getUpdatedCalls(calls: calls)
                userOp.callData = account.encodeCalls(args: updatedCalls)
            }

            if userOp.factory?.isEmpty ?? true || userOp.factoryData?.isEmpty ?? true {
                if let arg = try await account.getFactoryArgs() {
                    userOp.factory = arg.0
                    userOp.factoryData = arg.1
                }
            }

            if partialUserOp.maxFeePerGas?.isZero ?? true || partialUserOp.maxPriorityFeePerGas?.isZero ?? true {
                if estimateFeesPerGas == nil {
                    let defaultMaxFeePerGas = try UnitUtils.parseGweiToWei("3")
                    let defaultMaxPriorityFeePerGas = try UnitUtils.parseGweiToWei("1")
                    let two = BigInt(2)

                    let fees = try? await self.estimateFeesPerGas(
                        transport: account.client.transport,
                        feeValuesType: .eip1559
                    )

                    if partialUserOp.maxFeePerGas == nil {
                        userOp.maxFeePerGas = max(defaultMaxFeePerGas,
                                                  (fees?.maxFeePerGas ?? 0) * two)
                    }

                    if partialUserOp.maxPriorityFeePerGas == nil {
                        userOp.maxPriorityFeePerGas = max(defaultMaxPriorityFeePerGas,
                                                          (fees?.maxPriorityFeePerGas ?? 0) * two)
                    }

                } else if let r = await estimateFeesPerGas?(account, bundlerClient, userOp) {
                    if partialUserOp.maxFeePerGas == nil {
                        userOp.maxFeePerGas = r.maxFeePerGas
                    }
                    if partialUserOp.maxPriorityFeePerGas == nil {
                        userOp.maxPriorityFeePerGas = r.maxPriorityFeePerGas
                    }
                }
            }

            if partialUserOp.nonce?.isZero ?? true {
                userOp.nonce = try await Utils.getNonce(transport: account.client.transport,
                                                        address: account.getAddress(),
                                                        entryPoint: account.entryPoint)
            }

            if partialUserOp.signature?.isEmpty ?? true {
                userOp.signature = account.getStubSignature(userOp: partialUserOp)
            }

            var isPaymasterPopulated = false

            if paymaster != nil {
                let stubR: GetPaymasterStubDataResult?
                if let truePaymaster = paymaster as? Paymaster.True {
                    stubR = try? await self.getPaymasterStubData(
                        transport: transport,
                        userOp: userOp,
                        entryPoint: account.entryPoint,
                        chainId: bundlerClient.chain.chainId,
                        context: truePaymaster.paymasterContext
                    )
                } else if let clientPaymaster = paymaster as? Paymaster.Client {
                    stubR = try? await self.getPaymasterStubData(
                        transport: clientPaymaster.client.transport,
                        userOp: userOp,
                        entryPoint: account.entryPoint,
                        chainId: bundlerClient.chain.chainId,
                        context: clientPaymaster.paymasterContext
                    )
                } else {
                    throw BaseError(shortMessage: "Unsupported paymaster type")
                }

                isPaymasterPopulated = stubR?.isFinal ?? false

                userOp.paymaster = stubR?.paymaster
                userOp.paymasterVerificationGasLimit = stubR?.paymasterVerificationGasLimit
                userOp.paymasterPostOpGasLimit = stubR?.paymasterPostOpGasLimit
                userOp.paymasterData = stubR?.paymasterData
            }

            // If not all the gas properties are already populated, we will need to estimate the gas to fill the gas properties.
            if userOp.preVerificationGas == nil ||
                userOp.verificationGasLimit == nil ||
                userOp.callGasLimit == nil ||
                (paymaster != nil && userOp.paymasterVerificationGasLimit == nil) ||
                (paymaster != nil && userOp.paymasterPostOpGasLimit == nil) {

                // Some Bundlers fail if nullish gas values are provided for gas estimation :')
                // So we will need to set a default zeroish value.
                let tmpUserOp = userOp.copy()
                tmpUserOp.callGasLimit = .zero
                tmpUserOp.preVerificationGas = .zero

                if paymaster != nil {
                    tmpUserOp.paymasterVerificationGasLimit = .zero
                    tmpUserOp.paymasterPostOpGasLimit = .zero
                } else {
                    tmpUserOp.paymasterVerificationGasLimit = nil
                    tmpUserOp.paymasterPostOpGasLimit = nil
                }

                let r = try await estimateUserOperationGas(
                    transport: transport,
                    userOp: tmpUserOp,
                    entryPoint: account.entryPoint
                )
                userOp.callGasLimit = userOp.callGasLimit ?? r.callGasLimit
                userOp.preVerificationGas = userOp.preVerificationGas ?? r.preVerificationGas
                userOp.verificationGasLimit = userOp.verificationGasLimit ?? r.verificationGasLimit
                userOp.paymasterPostOpGasLimit = userOp.paymasterPostOpGasLimit ?? r.paymasterPostOpGasLimit
                userOp.paymasterVerificationGasLimit = userOp.paymasterVerificationGasLimit ?? r.paymasterVerificationGasLimit
            }

            if paymaster != nil, !isPaymasterPopulated {
                let r: GetPaymasterDataResult?
                if let truePaymaster = paymaster as? Paymaster.True {
                    r = try? await self.getPaymasterData(
                        transport: transport,
                        userOp: userOp,
                        entryPoint: account.entryPoint,
                        chainId: bundlerClient.chain.chainId,
                        context: truePaymaster.paymasterContext
                    )
                } else if let clientPaymaster = paymaster as? Paymaster.Client {
                    r = try? await self.getPaymasterData(
                        transport: clientPaymaster.client.transport,
                        userOp: userOp,
                        entryPoint: account.entryPoint,
                        chainId: bundlerClient.chain.chainId,
                        context: clientPaymaster.paymasterContext
                    )
                } else {
                    throw BaseError(shortMessage: "Unsupported paymaster type")
                }

                userOp.paymaster = r?.paymaster ?? userOp.paymaster
                userOp.paymasterVerificationGasLimit = r?.paymasterVerificationGasLimit ?? userOp.paymasterVerificationGasLimit
                userOp.paymasterPostOpGasLimit = r?.paymasterPostOpGasLimit ?? userOp.paymasterPostOpGasLimit
                userOp.paymasterData = r?.paymasterData ?? userOp.paymasterData
            }

            return userOp

        } catch let error as BaseError {
            throw error

        } catch {
            throw BaseError(shortMessage: error.localizedDescription,
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    func sendUserOperation(
        transport: Transport,
        partialUserOp: UserOperationV07,
        entryPointAddress: String
    ) async throws -> String {
        do {
            let req = RpcRequest(method: "eth_sendUserOperation",
                                 params: [AnyEncodable(partialUserOp),
                                          AnyEncodable(entryPointAddress)])
            let response = try await transport.request(req) as RpcResponse<String>

            return response.result

        } catch let error as BaseError {
            throw ErrorUtils.getUserOperationExecutionError(err: error, userOp: partialUserOp)

        } catch {
            let baseError = BaseError(shortMessage: error.localizedDescription,
                                      args: .init(cause: error, name: String(describing: error)))
            throw ErrorUtils.getUserOperationExecutionError(err: baseError, userOp: partialUserOp)
        }
    }

    func waitForUserOperationReceipt(
        transport: Transport,
        userOpHash: String,
        pollingInterval: Int,
        retryCount: Int,
        timeout: Int?
    ) async throws -> GetUserOperationReceiptResult {
        do {
            let result = try await Utils.startPolling(pollingInterval: pollingInterval,
                                                      retryCount: retryCount,
                                                      timeout: timeout) {
                try await getUserOperationReceipt(transport: transport, userOpHash: userOpHash)
            }
            return result

        } catch Utils.PollingError.timeout {
            throw WaitForUserOperationReceiptTimeoutError(hash: userOpHash)

        } catch {
            throw UserOperationReceiptNotFoundError(hash: userOpHash, cause: error)
        }
    }
}

extension BundlerRpcApi {

    func getUpdatedCalls(calls: [EncodeCallDataArg]) -> [EncodeCallDataArg] {
        let updatedCalls: [EncodeCallDataArg] = calls.map { call in
            if let abiJson = call.abiJson, !abiJson.isEmpty,
               let functionName = call.functionName, !functionName.isEmpty {
                return EncodeCallDataArg(
                    to: call.to,
                    value: call.value,
                    data: Utils.encodeFunctionData(
                        functionName: functionName,
                        abiJson: abiJson,
                        args: call.args ?? []
                    ),
                    abiJson: abiJson,
                    functionName: functionName,
                    args: call.args
                )
            } else {
                return call
            }
        }
        return updatedCalls
    }
}
