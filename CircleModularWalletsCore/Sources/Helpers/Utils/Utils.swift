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
import Web3Core
import web3swift
import BigInt
import CryptoKit

/// A utility struct providing essential helper methods for encoding, verification, and data processing
/// related to blockchain operations, WebAuthn integration, and ABI handling.
///
/// The `Utils` struct serves as a centralized collection of static functions that simplify common
/// operations such as encoding ABI functions, verifying digital signatures, generating hashes for user
/// operations, and creating calldata for blockchain transactions.
///
/// ## Features
/// - Encode function data for ABI-based smart contracts.
/// - Verify digital signatures using WebAuthn public keys.
/// - Generate hashes for user operations to ensure data integrity.
/// - Encode ERC20 token transfers and general contract executions into calldata.
/// - Support for common blockchain standards like EIP-1559 and WebAuthn.
///
/// ## Use Cases
/// - Simplify integration with smart contract operations in decentralized applications.
/// - Facilitate secure authentication workflows using WebAuthn.
/// - Enable seamless user operation handling for blockchain networks.
///
/// ### Example Usage
/// ```swift
/// let encodedData = Utils.encodeFunctionData(
///     functionName: "transfer",
///     abiJson: tokenABI,
///     args: ["0xRecipientAddress", "1000"]
/// )
///
/// let isVerified = try Utils.verify(
///     hash: "0xHash",
///     publicKey: "0xPublicKey",
///     signature: "0xSignature",
///     webauthn: webAuthnData
/// )
/// ```
public struct Utils {

    /// Encode abi function
    ///
    /// - Parameters:
    ///   - functionName: ABI function name
    ///   - abiJson: ABI json
    ///   - args: Input array for the ABI function
    ///
    /// - Returns: Encoded ABI function
    public static func encodeFunctionData(functionName: String,
                                          abiJson: String,
                                          args: [Any]) -> String? {
        guard let contract = try? EthereumContract(abiJson),
              let callData = contract.method(functionName, parameters: args, extraData: nil) else {
            logger.utils.notice("This abiJson cannot be parsed or the given contract method cannot be called with the given parameters")
            return nil
        }

        logger.utils.notice("callData:\n\(HexUtils.dataToHex(callData))")

        return HexUtils.dataToHex(callData)
    }

    /// Verifies a signature using the credential public key and the hash which was signed.
    ///
    /// - Parameters:
    ///   - hash: (hex) string
    ///   - publicKey: (serialized hex) string
    ///   - signature: (serialized hex) string
    ///   - webauthn: WebAuthnData
    ///
    /// - Returns: Verification success or failure
    public static func verify(hash: String,
                              publicKey: String,
                              signature: String,
                              webauthn: WebAuthnData) throws -> Bool {
        do {
            let rawClientData = webauthn.clientDataJSON.bytes
            let clientData = try JSONDecoder().decode(CollectedClientData.self, from: Data(rawClientData))
            let rawAuthenticatorData = try HexUtils.hexToBytes(hex: webauthn.authenticatorData)
            let authenticatorData = try AuthenticatorData(bytes: rawAuthenticatorData)

            guard let expectedChallengeData = HexUtils.hexToData(hex: hash) else {
                logger.utils.error("Failed to decode the hash (\"\(hash)\") hex string into Data struct.")
                return false
            }

            let publicKeyBytes = try HexUtils.hexToBytes(hex: publicKey)

            guard let signature = HexUtils.hexToData(hex: signature) else {
                logger.utils.error("Failed to decode the signature (\"\(signature)\") hex string into Data struct.")
                return false
            }

            try _verify(
                clientData: clientData,
                rawClientData: rawClientData,
                authenticatorData: authenticatorData,
                rawAuthenticatorData: rawAuthenticatorData,
                requireUserVerification: webauthn.userVerificationRequired,
                expectedChallenge: expectedChallengeData.bytes,
                credentialPublicKey: publicKeyBytes,
                signature: signature
            )
            return true
        } catch let error as DecodingError {
            throw BaseError(shortMessage: "Failed to get the CollectedClientData object from rawClientData.",
                            args: .init(cause: error, name: String(describing: error)))
        } catch let error as HexConversionError {
            throw BaseError(shortMessage: "Failed to decode the authenticatorData/publicKey hex string into UInt8 array.",
                            args: .init(cause: error, name: String(describing: error)))
        } catch let error as WebAuthnError {
            throw BaseError(shortMessage: "Failed to get the AuthenticatorData object from rawAuthenticatorData.",
                            args: .init(cause: error, name: String(describing: error)))
        } catch let error as BaseError {
            logger.webAuthn.notice("Error: \(error)")
            throw error
        } catch {
            logger.webAuthn.notice("Error: \(error)")
            throw BaseError(shortMessage: error.localizedDescription,
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    /// Generates the hash of a user operation.
    ///
    /// - Parameters:
    ///   - chainId: The ID of the blockchain network.
    ///   - entryPointAddress: The address of the entry point contract. Defaults to the address of `EntryPoint.V07`.
    ///   - userOp: The user operation to hash.
    ///
    /// - Returns: The hash of the user operation as a hex string.
    public static func getUserOperationHash(
        chainId: Int,
        entryPointAddress: String = ENTRYPOINT_V07_ADDRESS,
        userOp: UserOperationV07
    ) throws -> String {

        var accountGasLimits = [UInt8]()
        if let verificationGasLimit = userOp.verificationGasLimit,
           let callGasLimit = userOp.callGasLimit {

            let verificationGasLimitHex = try HexUtils.bigIntToHex(verificationGasLimit, withPrefix: false)
            let verificationGasLimitHexWithPadding = verificationGasLimitHex.leftPadding(toLength: 32, withPad: "0")
            let callGasLimitHex = try HexUtils.bigIntToHex(callGasLimit, withPrefix: false)
            let callGasLimitHexWithPadding = callGasLimitHex.leftPadding(toLength: 32, withPad: "0")
            let finalHex = verificationGasLimitHexWithPadding + callGasLimitHexWithPadding

            if let accountGasLimitsData = HexUtils.hexToData(hex: finalHex) {
                accountGasLimits = accountGasLimitsData.bytes
            }
        }

        var callDataHashed = Data()
        if let callDataHex = userOp.callData,
           let callData = HexUtils.hexToData(hex: callDataHex) {
            callDataHashed = callData.sha3(.keccak256)
        }

        var gasFees = [UInt8]()
        if let maxPriorityFeePerGas = userOp.maxPriorityFeePerGas,
           let maxFeePerGas = userOp.maxFeePerGas {

            let maxPriorityFeePerGasHex = try HexUtils.bigIntToHex(maxPriorityFeePerGas, withPrefix: false)
            let maxPriorityFeePerGasHexWithPadding = maxPriorityFeePerGasHex.leftPadding(toLength: 32, withPad: "0")
            let maxFeePerGasHex = try HexUtils.bigIntToHex(maxFeePerGas, withPrefix: false)
            let maxFeePerGasHexWithPadding = maxFeePerGasHex.leftPadding(toLength: 32, withPad: "0")
            let finalHex = maxPriorityFeePerGasHexWithPadding + maxFeePerGasHexWithPadding

            if let gasFeesData = HexUtils.hexToData(hex: finalHex) {
                gasFees = gasFeesData.bytes
            }
        }

        var initCodeHashed = Data()
        var initCodeHex = "0x"
        if let factory = userOp.factory,
           let factoryData = userOp.factoryData {
            initCodeHex = factory.noHexPrefix + factoryData.noHexPrefix
        }

        if let initCodeData = HexUtils.hexToData(hex: initCodeHex) {
            initCodeHashed = initCodeData.sha3(.keccak256)
        }

        var paymasterAndDataHashed = Data()
        var paymasterAndDataHex = "0x"
        if let paymaster = userOp.paymaster {

            let paymasterVerificationGasLimit = userOp.paymasterVerificationGasLimit ?? BigInt.zero
            let verificationGasLimitHex = try HexUtils.bigIntToHex(paymasterVerificationGasLimit, withPrefix: false)
            let verificationGasLimitHexWithPadding = verificationGasLimitHex.leftPadding(toLength: 32, withPad: "0")

            let paymasterPostOpGasLimit = userOp.paymasterPostOpGasLimit ?? BigInt.zero
            let postOpGasLimitHex = try HexUtils.bigIntToHex(paymasterPostOpGasLimit, withPrefix: false)
            let postOpGasLimitHexWithPadding = postOpGasLimitHex.leftPadding(toLength: 32, withPad: "0")

            let paymasterData = userOp.paymasterData?.noHexPrefix ?? ""

            paymasterAndDataHex = paymaster + verificationGasLimitHexWithPadding + postOpGasLimitHexWithPadding + paymasterData
        }

        if let paymasterAndData = HexUtils.hexToData(hex: paymasterAndDataHex) {
            paymasterAndDataHashed = paymasterAndData.sha3(.keccak256)
        }

        var types: [ABI.Element.ParameterType] = [
            .address,
            .uint(bits: 256),
            .bytes(length: 32),
            .bytes(length: 32),
            .bytes(length: 32),
            .uint(bits: 256),
            .bytes(length: 32),
            .bytes(length: 32)
        ]

        var values = [Any]()
        if let sender = userOp.sender,
           let nonce = userOp.nonce,
           let preVerificationGas = userOp.preVerificationGas {
            values = [
                sender,
                nonce,
                initCodeHashed,
                callDataHashed,
                accountGasLimits,
                preVerificationGas,
                gasFees,
                paymasterAndDataHashed
            ]
        }

        var packedUserOpData = Data()
        if let _packedUserOpData = ABIEncoder.encode(types: types, values: values) {
            packedUserOpData = _packedUserOpData
        }

        let packedUserOpHashed = packedUserOpData.sha3(.keccak256)

        logger.utils.debug("packedUserOp hashed : \(HexUtils.dataToHex(packedUserOpHashed))")

        types = [.bytes(length: 32), .address, .uint(bits: 256)]
        values = [packedUserOpHashed, entryPointAddress, chainId]

        var userOpData = Data()
        if let _userOpData = ABIEncoder.encode(types: types, values: values) {
            userOpData = _userOpData
        }

        let userOpHashed = userOpData.sha3(.keccak256)

        return HexUtils.dataToHex(userOpHashed)
    }

    /// Encodes an ERC20 token transfer into calldata for executing a User Operation.
    ///
    /// - Parameters:
    ///   - to: The recipient address.
    ///   - token: The token contract address or the name of the `Token` enum.
    ///   - amount: The amount to transfer.
    ///
    /// - Returns: The encoded transfer abi and contract address.
    public static func encodeTransfer(to: String,
                                      token: String,
                                      amount: BigInt) -> EncodeTransferResult {
        let abiParameters: [Any] = [to, amount]

        let encodedAbi = self.encodeFunctionData(
            functionName: "transfer",
            abiJson: ERC20_ABI,
            args: abiParameters
        )

        return EncodeTransferResult(data: encodedAbi ?? "0x",
                                    to: CONTRACT_ADDRESS[token] ?? token)
    }

    /// Encodes a contract execution into calldata for executing a User Operation.
    ///
    /// - Parameters:
    ///   - to: The recipient address.
    ///   - abiSignature: The ABI signature of the function.
    ///   - args: The arguments for the function call.
    ///   - value: The value to send with the transaction.
    ///
    /// - Returns: The encoded call data.
    public static func encodeContractExecution(
        to: String,
        abiSignature: String,
        args: [Any] = [],
        value: BigInt
    ) -> String {
        let signatureParts = abiSignature.split(separator: "(", maxSplits: 1)
        let functionName = String(signatureParts[0])
        let parameterTypesString = signatureParts[1].dropLast()
        let parameterTypes = parseParameterTypes(String(parameterTypesString))
        let function = ABI.Element.Function(name: functionName,
                                            inputs: parameterTypes,
                                            outputs: [],
                                            constant: false,
                                            payable: false)

        guard let encodedABI = function.encodeParameters(args) else {
            logger.utils.notice("Failed to encode parameters (\(args) of a given contract method")
            return ""
        }

        let arg = EncodeCallDataArg(
            to: to,
            value: value,
            data: HexUtils.dataToHex(encodedABI)
        )

        return Utils.encodeCallData(arg: arg)
    }
}

extension Utils {
    
    private typealias InOut = ABI.Element.InOut

    // MARK: Internal Usage

    static func _verify(
        clientData: CollectedClientData,
        rawClientData: [UInt8],
        authenticatorData: AuthenticatorData,
        rawAuthenticatorData: [UInt8],
        requireUserVerification: Bool,
        expectedChallenge: [UInt8],
        credentialPublicKey: [UInt8],
        signature: Data
    ) throws {
        try clientData.verify(storedChallenge: expectedChallenge,
                              ceremonyType: .assert)

        guard authenticatorData.flags.userPresent else { throw WebAuthnError.userPresentFlagNotSet }
        if requireUserVerification {
            guard authenticatorData.flags.userVerified else { throw WebAuthnError.userVerifiedFlagNotSet }
        }

        let clientDataHash = SHA256.hash(data: rawClientData)
        let signatureBase = rawAuthenticatorData + clientDataHash

        let credentialPublicKey = try CredentialPublicKey(publicKeyBytes: credentialPublicKey)
        try credentialPublicKey.verify(signature: signature, data: signatureBase)
    }

    /// ABI JSON:
    /// https://github.com/wevm/viem/blob/main/src/account-abstraction/accounts/implementations/toCoinbaseSmartAccount.ts#L553-L562
    static func encodeCallData(arg: EncodeCallDataArg) -> String {
        let functionName = "execute"
        let input1 = InOut(name: "target", type: .address)
        let input2 = InOut(name: "value", type: .uint(bits: 256))
        let input3 = InOut(name: "data", type: .dynamicBytes)
        let function = ABI.Element.Function(name: functionName,
                                            inputs: [input1, input2, input3],
                                            outputs: [],
                                            constant: false,
                                            payable: true)
        let params: [Any] = [arg.to, arg.value ?? BigInt(0), arg.data ?? "0x"]
        let encodedData = function.encodeParameters(params)
        return HexUtils.dataToHex(encodedData)
    }

    /// ABI JSON:
    /// https://github.com/wevm/viem/blob/main/src/account-abstraction/accounts/implementations/toCoinbaseSmartAccount.ts#L563-L580
    /// Logic:
    /// https://github.com/wevm/viem/blob/main/src/account-abstraction/accounts/implementations/toCoinbaseSmartAccount.ts#L122-L140
    static func encodeCallData(args: [EncodeCallDataArg]) -> String {
        if args.count == 1 {
            return encodeCallData(arg: args[0])
        }

        let functionName = "executeBatch"
        let tupleTypes: [ABI.Element.ParameterType] = [
            .address,
            .uint(bits: 256),
            .dynamicBytes
        ]
        let input = InOut(name: "calls", type: .array(type: .tuple(types: tupleTypes), length: 0))
        let function = ABI.Element.Function(name: functionName,
                                            inputs: [input],
                                            outputs: [],
                                            constant: false,
                                            payable: false)

        let params: [Any] = args.map {
            [$0.to, $0.value ?? BigInt(0), $0.data ?? "0x"]
        }
        let encodedData = function.encodeParameters([params])
        return HexUtils.dataToHex(encodedData)
    }

    static func encodePacked(_ parameters: [Any]) -> String {
        let encoded = parameters.reduce("") { (partialResult, parameter) in
            return partialResult + HexUtils.dataToHex(try? ABIEncoder.abiEncode(parameter), withPrefix: false)
        }
        return encoded
    }

    static func hashMessage(hex: String) -> String {
        var bytes = [UInt8]()

        if let _bytes = try? HexUtils.hexToBytes(hex: hex) {
            bytes = _bytes
        }

        return hashMessage(byteArray: bytes)
    }

    static func hashMessage(byteArray: [UInt8]) -> String {
        let hash = Utilities.hashPersonalMessage(Data(byteArray))
        return HexUtils.dataToHex(hash)
    }

    static func parseFactoryAddressAndData(initCode: String) -> (factoryAddress: String, factoryData: String) {
        guard initCode.count >= 42 else {
            logger.utils.error("initCode must be at least 42 characters long")
            return ("", "")
        }

        let factoryAddress = String(initCode.prefix(42))
        let factoryData = "0x\(initCode.dropFirst(42))"

        return (factoryAddress, factoryData)
    }

    static func parseParameterTypes(_ typesString: String) -> [ABI.Element.InOut] {
        guard !typesString.isEmpty else {
            return []
        }
        var currentTypeString = ""
        var types = [ABI.Element.InOut]()
        var tupleStack = [ABI.Element.ParameterType]()
        var arrayBalance = 0
        var tempTuple: ABI.Element.ParameterType?
        
        func popLastTupleFormStack() -> [ABI.Element.ParameterType]? {
            if let parameterType = tupleStack.popLast() {
                switch parameterType {
                case .tuple(types: let elements):
                    return elements
                default:
                    // Tuple stack could only store tuple, if not just return nil
                    return nil
                }
            } else {
                // Not a valid ABI signature
                return nil
            }
        }
        
        for i in 0..<typesString.count {
            switch Array(typesString)[i] {
            case "(":
                tupleStack.append(.tuple(types: []))
            case ")":
                if currentTypeString.isEmpty {
                    guard let elements = popLastTupleFormStack() else {
                        return []
                    }
                    let tuple = ABI.Element.ParameterType.tuple(types: elements)
                    // check next char is array or not
                    if (i + 1) < typesString.count && Array(typesString)[i + 1] == "[" {
                        tempTuple = tuple
                        continue
                    }
                    
                    if let elements = popLastTupleFormStack() {
                        tupleStack.append(.tuple(types: elements + [tuple]))
                    } else {
                        let type = ABI.Element.InOut(name: "", type: tuple)
                        types.append(type)
                    }
                    continue
                }
                
                guard let parsedABIType = try? ABITypeParser.parseTypeString(currentTypeString),
                      let elements = popLastTupleFormStack() else {
                    // Parse error
                    return []
                }
                currentTypeString = ""
                let tuple = ABI.Element.ParameterType.tuple(types: elements + [parsedABIType])
                // check next char is array or not
                if (i + 1) < typesString.count && Array(typesString)[i + 1] == "[" {
                    tempTuple = tuple
                    continue
                }
                
                if let elements = popLastTupleFormStack() {
                    tupleStack.append(.tuple(types: elements + [tuple]))
                } else {
                    let type = ABI.Element.InOut(name: "", type: tuple)
                    types.append(type)
                }
            case ",":
                if currentTypeString.isEmpty {
                    continue
                }
                guard let parsedABIType = try? ABITypeParser.parseTypeString(currentTypeString) else {
                    // Parse error
                    return []
                }
                if let elements = popLastTupleFormStack() {
                    let tuple = ABI.Element.ParameterType.tuple(types: elements + [parsedABIType])
                    tupleStack.append(tuple)
                } else {
                    let type = ABI.Element.InOut(name: "", type: parsedABIType)
                    types.append(type)
                }
                currentTypeString = ""
            case "[":
                arrayBalance += 1
            case "]":
                arrayBalance -= 1
                if arrayBalance != 0 {
                    return []
                }
                
                if let tuple = tempTuple {
                    let arr = ABI.Element.ParameterType.array(type: tuple, length: 0)
                    if let elements = popLastTupleFormStack() {
                        let tuple = ABI.Element.ParameterType.tuple(types: elements + [arr])
                        tupleStack.append(tuple)
                    } else {
                        let type = ABI.Element.InOut(name: "", type: arr)
                        types.append(type)
                    }
                    tempTuple = nil
                } else {
                    guard let parsedABIType = try? ABITypeParser.parseTypeString(currentTypeString) else {
                        return []
                    }
                    currentTypeString = ""
                    let arr = ABI.Element.ParameterType.array(type: parsedABIType, length: 0)
                    if let elements = popLastTupleFormStack() {
                        let tuple = ABI.Element.ParameterType.tuple(types: elements + [arr])
                        tupleStack.append(tuple)
                    } else {
                        let type = ABI.Element.InOut(name: "", type: arr)
                        types.append(type)
                    }
                }
            default:
                currentTypeString.append(Array(typesString)[i])
            }
        }
        
        // When there is no tuple
        if !currentTypeString.isEmpty {
            guard let parsedABIType = try? ABITypeParser.parseTypeString(currentTypeString) else {
                return []
            }
            if popLastTupleFormStack() != nil {
                // In this case, there's an opening parenthesis but no closing parenthesis.
                // test case "(string"
                return []
            }
            let type = ABI.Element.InOut(name: "", type: parsedABIType)
            types.append(type)
        }
        
        return types
    }

    enum PollingError: Error {
        case timeout
        case noResult
    }

    ///  Starts polling for a result by repeatedly executing a given asynchronous block.
    ///
    /// - Parameters:
    ///   - pollingInterval: The time interval in milliseconds between each polling attempt.
    ///   - retryCount: The maximum number of times to retry polling if a result is not obtained.
    ///   - timeout: An optional timeout period in seconds. If provided, the polling will stop if this duration is exceeded.
    ///   - block: An asynchronous closure that returns a value of type T? which will be polled repeatedly.
    ///
    /// - Throws:
    ///   - PollingError.timeoutError if the polling operation exceeds the specified timeout period.
    ///
    /// - Returns: An optional value of type T? if a result is obtained within the allowed polling attempts and timeout period.
    static func startPolling<T>(pollingInterval: Int,
                                retryCount: Int,
                                timeout: Int?,
                                block: @escaping () async throws -> T) async throws -> T {

        logger.utils.debug("Start polling, retryCount: \(retryCount)")

        var currentCount = 0
        let startTime = Date() // Record the start time

        while currentCount < retryCount {
            logger.utils.debug("Polling currentCount: \(currentCount)")

            if let result = try? await block() {
                logger.utils.debug("Polling got result: \(currentCount)")
                return result
            }

            // Check if the timeout has been exceeded
            if let timeout = timeout, Date().timeIntervalSince(startTime) > Double(timeout) {
                throw PollingError.timeout
            }

            currentCount += 1
            try? await Task.sleep(nanoseconds: UInt64(pollingInterval) * 1_000_000) // Convert milliseconds to nanoseconds
        }

        throw PollingError.noResult
    }

    static func pemToCOSE(pemKey: String) throws -> [UInt8] {
        // 1. Decode Base64URL string
        guard let keyBytes = URLEncodedBase64(pemKey).decodedBytes else {
            throw BaseError(shortMessage: "PEMToCOSE(pemKey: \"\(pemKey)\" Invalid Base64URL encoding")
        }

        // 2. Composition PEM Document format
        let pemStrs = Data(keyBytes).base64EncodedString().split(every: 64)
        var pemDocument = "-----BEGIN PUBLIC KEY-----\n"
        pemStrs.forEach {
            pemDocument += $0 + "\n"
        }
        pemDocument += "-----END PUBLIC KEY-----"

        do {
            // 3. Parse public key data
            let publicKey = try P256.Signing.PublicKey(pemRepresentation: pemDocument)

            // 4. Construct COSE format
            var coseKey: [UInt8] = []

            // COSE Key Common Parameters
            coseKey.append(contentsOf: [
                0xa5,  // map of 5 pairs
                0x01, 0x02,  // kty: EC2
                0x03, 0x26,  // alg: ES256 (-7) in CBOR encoding
                0x20, 0x01,  // crv: P-256
            ])

            // Public Key X coordinate
            coseKey.append(0x21)  // x coordinate (negative integer for key -2)
            coseKey.append(0x58)  // bytes
            coseKey.append(0x20)  // 32 bytes
            coseKey.append(contentsOf: publicKey.rawRepresentation.prefix(32))

            // Public Key Y coordinate
            coseKey.append(0x22)  // y coordinate (negative integer for key -3)
            coseKey.append(0x58)  // bytes
            coseKey.append(0x20)  // 32 bytes
            coseKey.append(contentsOf: publicKey.rawRepresentation.suffix(32))

            return coseKey
        } catch {
            throw BaseError(shortMessage: "Failed to parse public key data (\(error))",
                            args: .init(cause: error, name: String(describing: error)))
        }
    }

    // Function to extract r and s from a DER-encoded ECDSA signature
    static func extractRSFromDER(_ signatureHex: String) -> (r: Data, s: Data)? {

        // 1. The signature in DER format should be encoded using ASN.1.
        guard let signatureData = HexUtils.hexToData(hex: signatureHex) else {
            logger.utils.notice("Invalid hexadecimal signature string")
            return nil
        }

        // 2. Parse the DER-encoded signature
        var offset = 0

        // 3. Check the signature starts with the correct identifier for a SEQUENCE (0x30)
        guard signatureData[offset] == 0x30 else {

            logger.utils.notice("Invalid signature")
            return nil
        }
        offset += 1

        // 4. Check that the length of the SEQUENCE matches the total length of the signature data
        guard signatureData[offset] == signatureData.count - 2 else {
            logger.utils.notice("Invalid signature")
            return nil
        }
        offset += 1

        // 5. Check for the INTEGER identifier (0x02) and reads the length of r,
        // then extracts the corresponding bytes.
        guard signatureData[offset] == 0x02 else {
            logger.utils.notice("Invalid signature")
            return nil
        }
        offset += 1

        let rLength = Int(signatureData[offset])
        offset += 1

        let r = signatureData[offset..<offset + rLength]
        offset += rLength

        // 6. Similar to r, it checks for the INTEGER identifier (0x02), reads the length of s,
        // and then extracts the bytes.
        guard signatureData[offset] == 0x02 else {
            logger.utils.notice("Invalid signature")
            return nil
        }
        offset += 1

        let sLength = Int(signatureData[offset])
        offset += 1

        let s = signatureData[offset..<offset + sLength]

        return (r, s)
    }

    // Function to create a DER-encoded ECDSA signature from r and s
    static func packRSIntoDer(_ signature: (r: Data, s: Data)) -> String {
        // 1. DER encoding format
        let rLength = signature.r.count
        let sLength = signature.s.count

        // 2. Build the DER encoded data
        var der = Data()

        // 3. Add sequence tag
        der.append(0x30) // SEQUENCE
        der.append(UInt8(rLength + sLength + 4)) // Length of the entire sequence

        // 4. Add r
        der.append(0x02) // INTEGER
        der.append(UInt8(rLength)) // Length of r
        der.append(signature.r) // Value of s

        // 5. Add s
        der.append(0x02) // INTEGER
        der.append(UInt8(sLength)) // Length of s
        der.append(signature.s) // Value of s

        return HexUtils.dataToHex(der)
    }

    static func toData(value: String) -> Data {
        let data: Data

        if value.isHex {
            data = HexUtils.hexToData(hex: value) ?? .init()
        } else {
            data = Data(value.utf8)
        }

        return data
    }

    static func toSha3Data(message: String) -> Data {
        let digest: Data

        if message.isHex {
            digest = (HexUtils.hexToData(hex: message) ?? .init()).sha3(.keccak256)
        } else {
            digest = Data(message.utf8).sha3(.keccak256)
        }

        return digest
    }

    // Function to pad Data to a specified size
    static func pad(data: Data, size: Int = 32, isRight: Bool = false) -> Data {
        // Check if the size of bytes exceeds the specified size
        if data.count > size {
            return data.suffix(size)
        }

        // Create a Data object for padded bytes
        var paddedData = Data(repeating: 0, count: size)

        for i in 0..<size {
            let padEnd = isRight
            if padEnd {
                paddedData[i] = i < data.count ? data[i] : 0
            } else {
                paddedData[size - i - 1] = i < data.count ? data[data.count - i - 1] : 0
            }
        }

        return paddedData
    }

    static func isValidSignature(
        transport: Transport,
        message: String,
        signature: String,
        from: String,
        to: String = CIRCLE_WEIGHTED_WEB_AUTHN_MULTISIG_PLUGIN
    ) async -> Bool {
        let digest = toSha3Data(message: message)
        
        let functionName = "isValidSignature"
        let input1 = InOut(name: "digest", type: .bytes(length: 32))
        let input2 = InOut(name: "signature", type: .dynamicBytes)
        let output = InOut(name: "magicValue", type: .bytes(length: 4))
        let function = ABI.Element.Function(name: functionName,
                                            inputs: [input1, input2],
                                            outputs: [output],
                                            constant: false,
                                            payable: false)
        let params: [Any] = [digest, signature]
        guard let data = function.encodeParameters(params) else {
            logger.utils.notice("isValidSignature function encodeParameters failure")
            return false
        }

        guard let fromAddress = EthereumAddress(from), let toAddress = EthereumAddress(to) else {
            logger.utils.notice("Invalid 'from' or 'to' address")
            return false
        }

        var transaction = CodableTransaction(to: toAddress, data: data)
        transaction.from = fromAddress
        
        guard let callResult = try? await Utils().ethCall(transport: transport,
                                                          transaction: transaction) else {
            logger.utils.notice("Failed to execute eth_call request")
            return false
        }

        guard let callResultData = HexUtils.hexToData(hex: callResult),
              let decoded = try? function.decodeReturnData(callResultData) else {
            logger.utils.notice("isValidSignature function decodeReturnData failure")
            return false
        }

        guard let magicValue = decoded["0"] as? Data else {
            logger.utils.notice("The data type returned by eth_call request is incorrect")
            return false
        }

        return EIP1271_VALID_SIGNATURE == magicValue.bytes
    }

    static func getCurrentDateTime() -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        let currentDate = Date()
        return dateFormatter.string(from: currentDate)
    }
}

extension Utils: PublicRpcApi {

    static func getNonce(transport: Transport,
                         address: String,
                         entryPoint: EntryPoint,
                         key: BigUInt = BigUInt(0)) async throws -> BigInt {
        let functionName = "getNonce"
        let input1 = InOut(name: "address", type: .address)
        let input2 = InOut(name: "key", type: .uint(bits: 192))
        let output = InOut(name: "object", type: .uint(bits: 256))
        let function = ABI.Element.Function(name: functionName,
                                            inputs: [input1, input2],
                                            outputs: [output],
                                            constant: false,
                                            payable: false)
        let params: [Any] = [address, key]

        guard let toAddress = EthereumAddress(entryPoint.address) else {
            throw BaseError(shortMessage: "Invalid 'to' address (\(entryPoint.address))")
        }

        guard let data = function.encodeParameters(params) else {
            throw BaseError(shortMessage: "Failed to encode parameters (\(params) of a given contract method")
        }
        logger.utils.debug("getNonce function encoded data:\n\(data.toHexString())")

        let transaction = CodableTransaction(to: toAddress, data: data)
        let callResult = try await Utils().ethCall(transport: transport,
                                                   transaction: transaction)
        guard let bigInt = HexUtils.hexToBigInt(hex: callResult) else {
            let error = CommonError.invalidHexString
            throw BaseError(shortMessage: "Failed to convert the hex (\"\(callResult)\") string to BigInt",
                            args: .init(cause: error, name: String(describing: error)))
        }

        return bigInt
    }
}
