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

struct ErrorUtils {

    static func getRpcError(cause: RpcRequestError) -> RpcError {

        switch cause.code {
        case ParseRpcError.code:
            return ParseRpcError(cause: cause)
        case InvalidRequestRpcError.code:
            return InvalidRequestRpcError(cause: cause)
        case MethodNotFoundRpcError.code:
            return MethodNotFoundRpcError(cause: cause)
        case InvalidParamsRpcError.code:
            return InvalidParamsRpcError(cause: cause)
        case InternalRpcError.code:
            return InternalRpcError(cause: cause)
        case InvalidInputRpcError.code:
            return InvalidInputRpcError(cause: cause)
        case ResourceNotFoundRpcError.code:
            return ResourceNotFoundRpcError(cause: cause)
        case ResourceUnavailableRpcError.code:
            return ResourceUnavailableRpcError(cause: cause)
        case TransactionRejectedRpcError.code:
            return TransactionRejectedRpcError(cause: cause)
        case MethodNotSupportedRpcError.code:
            return MethodNotSupportedRpcError(cause: cause)
        case LimitExceededRpcError.code:
            return LimitExceededRpcError(cause: cause)
        case JsonRpcVersionUnsupportedError.code:
            return JsonRpcVersionUnsupportedError(cause: cause)

        case UserRejectedRequestError.code:
            return UserRejectedRequestError(cause: cause)
        case UnauthorizedProviderError.code:
            return UnauthorizedProviderError(cause: cause)
        case UnsupportedProviderMethodError.code:
            return UnsupportedProviderMethodError(cause: cause)
        case ProviderDisconnectedError.code:
            return ProviderDisconnectedError(cause: cause)
        case ChainDisconnectedError.code:
            return ChainDisconnectedError(cause: cause)
        case SwitchChainError.code:
            return SwitchChainError(cause: cause)

        default:
            return UnknownRpcError(cause: cause)
        }
    }

    static func getUserOperationExecutionError(err: BaseError, userOp: UserOperation?) -> BaseError {
        let cause = getBundlerError(err: err, userOp: userOp)
        return UserOperationExecutionError(cause: cause,
                                           userOp: userOp ?? UserOperationV07())
    }

    static func getBundlerError(err: BaseError, userOp: UserOperation?) -> BaseError {

        // 1. Try to map BundlerError from message

        let message = err.details?.lowercased() ?? ""

        if message.contains(AccountNotDeployedError.message) { return AccountNotDeployedError(cause: err) }
        else if message.contains(FailedToSendToBeneficiaryError.message) { return FailedToSendToBeneficiaryError(cause: err) }
        else if message.contains(GasValuesOverflowError.message) { return GasValuesOverflowError(cause: err) }
        else if message.contains(HandleOpsOutOfGasError.message) { return HandleOpsOutOfGasError(cause: err) }
        else if message.contains(InitCodeFailedError.message) {
            return InitCodeFailedError(
                cause: err,
                factory: (userOp as? UserOperationV07)?.factory,
                factoryData: (userOp as? UserOperationV07)?.factoryData
            )
        }
        else if message.contains(InitCodeMustCreateSenderError.message) {
            return InitCodeMustCreateSenderError(
                cause: err,
                factory: (userOp as? UserOperationV07)?.factory,
                factoryData: (userOp as? UserOperationV07)?.factoryData
            )
        }
        else if message.contains(InitCodeMustReturnSenderError.message) {
            return InitCodeMustReturnSenderError(
                cause: err,
                factory: (userOp as? UserOperationV07)?.factory,
                factoryData: (userOp as? UserOperationV07)?.factoryData,
                sender: (userOp as? UserOperationV07)?.sender
            )
        }
        else if message.contains(InsufficientPrefundError.message) { return InsufficientPrefundError(cause: err) }
        else if message.contains(InternalCallOnlyError.message) { return InternalCallOnlyError(cause: err) }
        else if message.contains(InvalidAggregatorError.message) { return InvalidAggregatorError(cause: err) }
        else if message.contains(InvalidAccountNonceError.message) {
            return InvalidAccountNonceError(cause: err, nonce: userOp?.nonce)
        }
        else if message.contains(InvalidBeneficiaryError.message) { return InvalidBeneficiaryError(cause: err) }
        else if message.contains(InvalidPaymasterAndDataError.message) { return InvalidPaymasterAndDataError(cause: err) }
        else if message.contains(PaymasterDepositTooLowError.message) { return PaymasterDepositTooLowError(cause: err) }
        else if message.contains(PaymasterFunctionRevertedError.message) { return PaymasterFunctionRevertedError(cause: err) }
        else if message.contains(PaymasterNotDeployedError.message) { return PaymasterNotDeployedError(cause: err) }
        else if message.contains(PaymasterPostOpFunctionRevertedError.message) { return PaymasterPostOpFunctionRevertedError(cause: err) }
        else if message.contains(SenderAlreadyConstructedError.message) {
            return SenderAlreadyConstructedError(
                cause: err,
                factory: (userOp as? UserOperationV07)?.factory,
                factoryData: (userOp as? UserOperationV07)?.factoryData
            )
        }
        else if message.contains(SmartAccountFunctionRevertedError.message) { return SmartAccountFunctionRevertedError(cause: err) }
        else if message.contains(UserOperationExpiredError.message) { return UserOperationExpiredError(cause: err) }
        else if message.contains(UserOperationPaymasterExpiredError.message) { return UserOperationPaymasterExpiredError(cause: err) }
        else if message.contains(UserOperationSignatureError.message) { return UserOperationSignatureError(cause: err) }
        else if message.contains(UserOperationPaymasterSignatureError.message) { return UserOperationPaymasterSignatureError(cause: err) }
        else if message.contains(VerificationGasLimitExceededError.message) { return VerificationGasLimitExceededError(cause: err) }
        else if message.contains(VerificationGasLimitTooLowError.message) { return VerificationGasLimitTooLowError(cause: err) }

        // 2. Try to map BundlerError from error code

        if let rpcError = err as? RpcRequestError {

            switch rpcError.code {
            case ExecutionRevertedError.code: return ExecutionRevertedError(cause: err, message: err.details)
            case InvalidFieldsError.code: return InvalidFieldsError(cause: err)
            case PaymasterDepositTooLowError.code: return PaymasterDepositTooLowError(cause: err)
            case PaymasterRateLimitError.code: return PaymasterRateLimitError(cause: err)
            case PaymasterStakeTooLowError.code: return PaymasterStakeTooLowError(cause: err)
            case SignatureCheckFailedError.code: return SignatureCheckFailedError(cause: err)
            case UnsupportedSignatureAggregatorError.code: return UnsupportedSignatureAggregatorError(cause: err)
            case UserOperationRejectedByEntryPointError.code: return UserOperationRejectedByEntryPointError(cause: err)
            case UserOperationRejectedByPaymasterError.code: return UserOperationRejectedByPaymasterError(cause: err)
            case UserOperationRejectedByOpCodeError.code: return UserOperationRejectedByOpCodeError(cause: err)
            case UserOperationOutOfTimeRangeError.code: return UserOperationOutOfTimeRangeError(cause: err)
            default: break
            }
        }

        // 3. Error message or error code not found.

        return UnknownBundlerError(cause: err)
    }

}
