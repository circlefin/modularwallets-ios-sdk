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

@_documentation(visibility: private)
public class AccountNotDeployedError: BaseError, @unchecked Sendable {
    static let message = "aa20"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Smart Account is not deployed.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: [
                        "This could arise when:",
                        "- No `factory`/`factoryData` or `initCode` properties are provided for Smart Account deployment.",
                        "- An incorrect `sender` address is provided."
                    ],
                    name: "AccountNotDeployedError"
                   ))
    }
}

@_documentation(visibility: private)
public class ExecutionRevertedError: BaseError, @unchecked Sendable {
    static let code: Int = -32521

    init(cause: BaseError? = nil, message: String? = nil) {
        super.init(shortMessage: ExecutionRevertedError.getMessage(message),
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "ExecutionRevertedError"
                   ))
    }

    static func getMessage(_ message: String? = nil) -> String {
        let reason = message?
            .replacingOccurrences(of: "execution reverted: ", with: "")
            .replacingOccurrences(of: "execution reverted", with: "")

        if let reason, !reason.isEmpty {
            return "Execution reverted with reason: \(reason)."
        } else {
            return "Execution reverted for an unknown reason."
        }
    }
}

@_documentation(visibility: private)
public class FailedToSendToBeneficiaryError: BaseError, @unchecked Sendable {
    static let message = "aa91"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Failed to send funds to beneficiary.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "FailedToSendToBeneficiaryError"
                   ))
    }
}

@_documentation(visibility: private)
public class GasValuesOverflowError: BaseError, @unchecked Sendable {
    static let message = "aa94"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Gas value overflowed.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: [
                        "This could arise when:",
                        "- one of the gas values exceeded 2**120 (uint120)"
                    ],
                    name: "GasValuesOverflowError"
                   ))
    }
}

@_documentation(visibility: private)
public class HandleOpsOutOfGasError: BaseError, @unchecked Sendable {
    static let message = "aa95"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "The `handleOps` function was called by the Bundler with a gas limit too low.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "HandleOpsOutOfGasError"
                   ))
    }
}

@_documentation(visibility: private)
public class InitCodeFailedError: BaseError, @unchecked Sendable {
    static let message = "aa13"

    init(cause: BaseError? = nil, factory: String? = nil, factoryData: String? = nil, initCode: String? = nil) {
        var metaMessages = [
            "This could arise when:",
            "- Invalid `factory`/`factoryData` or `initCode` properties are present",
            "- Smart Account deployment execution ran out of gas (low `verificationGasLimit` value)",
            "- Smart Account deployment execution reverted with an error"
        ]

        if let factory = factory {
            metaMessages.append("factory: \(factory)")
        }
        if let factoryData = factoryData {
            metaMessages.append("factoryData: \(factoryData)")
        }
        if let initCode = initCode {
            metaMessages.append("initCode: \(initCode)")
        }

        super.init(shortMessage: "Failed to simulate deployment for Smart Account.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: metaMessages,
                    name: "InitCodeFailedError"
                   ))
    }
}

@_documentation(visibility: private)
public class InitCodeMustCreateSenderError: BaseError, @unchecked Sendable {
    static let message = "aa15"

    init(cause: BaseError? = nil, factory: String? = nil, factoryData: String? = nil, initCode: String? = nil) {
        var metaMessages = [
            "This could arise when:",
            "- `factory`/`factoryData` or `initCode` properties are invalid",
            "- Smart Account initialization implementation is incorrect\n"
        ]

        if let factory = factory {
            metaMessages.append("factory: \(factory)")
        }
        if let factoryData = factoryData {
            metaMessages.append("factoryData: \(factoryData)")
        }
        if let initCode = initCode {
            metaMessages.append("initCode: \(initCode)")
        }

        super.init(shortMessage: "Smart Account initialization implementation did not create an account.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: metaMessages,
                    name: "InitCodeMustCreateSenderError"
                   ))
    }
}

@_documentation(visibility: private)
public class InitCodeMustReturnSenderError: BaseError, @unchecked Sendable {
    static let message = "aa14"

    init(cause: BaseError? = nil, factory: String? = nil, factoryData: String? = nil, initCode: String? = nil, sender: String? = nil) {
        var metaMessages = [
            "This could arise when:",
            "Smart Account initialization implementation does not return a sender address\n"
        ]

        if let factory = factory {
            metaMessages.append("factory: \(factory)")
        }
        if let factoryData = factoryData {
            metaMessages.append("factoryData: \(factoryData)")
        }
        if let initCode = initCode {
            metaMessages.append("initCode: \(initCode)")
        }
        if let sender = sender {
            metaMessages.append("sender: \(sender)")
        }

        super.init(shortMessage: "Smart Account initialization implementation does not return the expected sender.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: metaMessages,
                    name: "InitCodeMustReturnSenderError"
                   ))
    }
}

@_documentation(visibility: private)
public class InsufficientPrefundError: BaseError, @unchecked Sendable {
    static let message = "aa21"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Smart Account does not have sufficient funds to execute the User Operation.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: [
                        "This could arise when:",
                        "- the Smart Account does not have sufficient funds to cover the required prefund, or",
                        "- a Paymaster was not provided."
                    ],
                    name: "InsufficientPrefundError"
                   ))
    }
}

@_documentation(visibility: private)
public class InternalCallOnlyError: BaseError, @unchecked Sendable {
    static let message = "aa92"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Bundler attempted to call an invalid function on the EntryPoint.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "InternalCallOnlyError"
                   ))
    }
}

@_documentation(visibility: private)
public class InvalidAggregatorError: BaseError, @unchecked Sendable {
    static let message = "aa96"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Bundler used an invalid aggregator for handling aggregated User Operations.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "InvalidAggregatorError"
                   ))
    }
}

@_documentation(visibility: private)
public class InvalidAccountNonceError: BaseError, @unchecked Sendable {
    static let message = "aa25"

    init(cause: BaseError? = nil, nonce: BigInt? = nil) {
        var metaMessages: [String]? = nil
        if let nonce {
            metaMessages = ["nonce: \(nonce)"]
        }
        super.init(shortMessage: "Invalid Smart Account nonce used for User Operation.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: metaMessages,
                    name: "InvalidAccountNonceError"
                   ))
    }
}

@_documentation(visibility: private)
public class InvalidBeneficiaryError: BaseError, @unchecked Sendable {
    static let message = "aa90"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Bundler has not set a beneficiary address.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "InvalidBeneficiaryError"
                   ))
    }
}

@_documentation(visibility: private)
public class InvalidFieldsError: BaseError, @unchecked Sendable {
    static let code: Int = -32602

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Invalid fields set on User Operation.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "InvalidFieldsError"
                   ))
    }
}

@_documentation(visibility: private)
public class InvalidPaymasterAndDataError: BaseError, @unchecked Sendable {
    static let message = "aa93"

    init(cause: BaseError? = nil, paymasterAndData: String? = nil) {
        var metaMessages = [
            "This could arise when:",
            "- the `paymasterAndData` property is of an incorrect length\n"
        ]

        if let paymasterAndData = paymasterAndData {
            metaMessages.append("paymasterAndData: \(paymasterAndData)")
        }

        super.init(shortMessage: "Paymaster properties provided are invalid.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: metaMessages,
                    name: "InvalidPaymasterAndDataError"
                   ))
    }
}

@_documentation(visibility: private)
public class PaymasterDepositTooLowError: BaseError, @unchecked Sendable {
    static let code: Int = -32508
    static let message = "aa31"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Paymaster deposit for the User Operation is too low.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: [
                        "This could arise when:",
                        "- the Paymaster has deposited less than the expected amount via the `deposit` function"
                    ],
                    name: "PaymasterDepositTooLowError"
                   ))
    }
}

@_documentation(visibility: private)
public class PaymasterFunctionRevertedError: BaseError, @unchecked Sendable {
    static let message = "aa33"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "The `validatePaymasterUserOp` function on the Paymaster reverted.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "PaymasterFunctionRevertedError"
                   ))
    }
}

@_documentation(visibility: private)
public class PaymasterNotDeployedError: BaseError, @unchecked Sendable {
    static let message = "aa30"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "The Paymaster contract has not been deployed.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "PaymasterNotDeployedError"
                   ))
    }
}

@_documentation(visibility: private)
public class PaymasterRateLimitError: BaseError, @unchecked Sendable {
    static let code: Int = -32504

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "UserOperation rejected because paymaster (or signature aggregator) is throttled/banned.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "PaymasterRateLimitError"
                   ))
    }
}

@_documentation(visibility: private)
public class PaymasterStakeTooLowError: BaseError, @unchecked Sendable {
    static let code: Int = -32505

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "UserOperation rejected because paymaster (or signature aggregator) is throttled/banned.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "PaymasterStakeTooLowError"
                   ))
    }
}

@_documentation(visibility: private)
public class PaymasterPostOpFunctionRevertedError: BaseError, @unchecked Sendable {
    static let message = "aa50"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Paymaster `postOp` function reverted.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "PaymasterPostOpFunctionRevertedError"
                   ))
    }
}

@_documentation(visibility: private)
public class SenderAlreadyConstructedError: BaseError, @unchecked Sendable {
    static let message = "aa10"

    init(cause: BaseError? = nil, factory: String? = nil, factoryData: String? = nil, initCode: String? = nil) {
        var metaMessages = [
            "Remove the following properties and try again:"
        ]
        if factory != nil {
            metaMessages.append("`factory`")
        }
        if factoryData != nil {
            metaMessages.append("`factoryData`")
        }
        if initCode != nil {
            metaMessages.append("`initCode`")
        }
        super.init(shortMessage: "Smart Account has already been deployed.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: metaMessages,
                    name: "SenderAlreadyConstructedError"
                   ))
    }
}

@_documentation(visibility: private)
public class SignatureCheckFailedError: BaseError, @unchecked Sendable {
    static let code: Int = -32507

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "UserOperation rejected because account signature check failed (or paymaster signature, if the paymaster uses its data as signature).",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "SignatureCheckFailedError"
                   ))
    }
}

@_documentation(visibility: private)
public class SmartAccountFunctionRevertedError: BaseError, @unchecked Sendable {
    static let message = "aa23"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "The `validateUserOp` function on the Smart Account reverted.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "SmartAccountFunctionRevertedError"
                   ))
    }
}

@_documentation(visibility: private)
public class UnsupportedSignatureAggregatorError: BaseError, @unchecked Sendable {
    static let code: Int = -32506

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "UserOperation rejected because account specified unsupported signature aggregator.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "UnsupportedSignatureAggregatorError"
                   ))
    }
}

@_documentation(visibility: private)
public class UserOperationExpiredError: BaseError, @unchecked Sendable {
    static let message = "aa22"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "User Operation expired.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: [
                        "This could arise when:",
                        "- the `validAfter` or `validUntil` values returned from `validateUserOp` on the Smart Account are not satisfied"
                    ],
                    name: "UserOperationExpiredError"
                   ))
    }
}

@_documentation(visibility: private)
public class UserOperationPaymasterExpiredError: BaseError, @unchecked Sendable {
    static let message = "aa32"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Paymaster for User Operation expired.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: [
                        "This could arise when:",
                        "- the `validAfter` or `validUntil` values returned from `validatePaymasterUserOp` on the Paymaster are not satisfied"
                    ],
                    name: "UserOperationPaymasterExpiredError"
                   ))
    }
}

@_documentation(visibility: private)
public class UserOperationSignatureError: BaseError, @unchecked Sendable {
    static let message = "aa24"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Signature provided for the User Operation is invalid.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: [
                        "This could arise when:",
                        "- the `signature` for the User Operation is incorrectly computed, and unable to be verified by the Smart Account"
                    ],
                    name: "UserOperationSignatureError"
                   ))
    }
}

@_documentation(visibility: private)
public class UserOperationPaymasterSignatureError: BaseError, @unchecked Sendable {
    static let message = "aa34"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "Signature provided for the User Operation is invalid.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: [
                        "This could arise when:",
                        "- the `signature` for the User Operation is incorrectly computed, and unable to be verified by the Paymaster"
                    ],
                    name: "UserOperationPaymasterSignatureError"
                   ))
    }
}

@_documentation(visibility: private)
public class UserOperationRejectedByEntryPointError: BaseError, @unchecked Sendable {
    static let code: Int = -32500

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "User Operation rejected by EntryPoint's `simulateValidation` during account creation or validation.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "UserOperationRejectedByEntryPointError"
                   ))
    }
}

@_documentation(visibility: private)
public class UserOperationRejectedByPaymasterError: BaseError, @unchecked Sendable {
    static let code: Int = -32501

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "User Operation rejected by Paymaster's `validatePaymasterUserOp`.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "UserOperationRejectedByPaymasterError"
                   ))
    }
}

@_documentation(visibility: private)
public class UserOperationRejectedByOpCodeError: BaseError, @unchecked Sendable {
    static let code: Int = -32502

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "User Operation rejected with op code validation error.",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "UserOperationRejectedByOpCodeError"
                   ))
    }
}

@_documentation(visibility: private)
public class UserOperationOutOfTimeRangeError: BaseError, @unchecked Sendable {
    static let code: Int = -32503

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "UserOperation out of time-range: either wallet or paymaster returned a time-range, and it is already expired (or will expire soon).",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "UserOperationOutOfTimeRangeError"
                   ))
    }
}

@_documentation(visibility: private)
public class VerificationGasLimitExceededError: BaseError, @unchecked Sendable {
    static let message = "aa40"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "User Operation verification gas limit exceeded.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: [
                        "This could arise when:",
                        "- the gas used for verification exceeded the `verificationGasLimit`"
                    ],
                    name: "VerificationGasLimitExceededError"
                   ))
    }
}

@_documentation(visibility: private)
public class VerificationGasLimitTooLowError: BaseError, @unchecked Sendable {
    static let message = "aa41"

    init(cause: BaseError? = nil) {
        super.init(shortMessage: "User Operation verification gas limit is too low.",
                   args: BaseErrorParameters(
                    cause: cause,
                    metaMessages: [
                        "This could arise when:",
                        "- the `verificationGasLimit` is too low to verify the User Operation"
                    ],
                    name: "VerificationGasLimitTooLowError"
                   ))
    }
}

@_documentation(visibility: private)
public class UnknownBundlerError: BaseError, @unchecked Sendable {
    init(cause: BaseError? = nil) {
        super.init(shortMessage: "An error occurred while executing user operation: \(cause?.shortMessage ?? "Unknown error")",
                   args: BaseErrorParameters(
                    cause: cause,
                    name: "UnknownBundlerError"
                   ))
    }
}
