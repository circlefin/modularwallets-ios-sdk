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
import web3swift

class WebAuthnCircleSmartAccountDelegate: CircleSmartAccountDelegate {

    static let WALLET_PREFIX = "passkey"

    private let owner: WebAuthnAccount

    init(_ owner: WebAuthnAccount) {
        self.owner = owner
    }

    func getModularWalletAddress(
        transport: ModularTransport,
        version: String,
        name: String?
    ) async throws -> ModularWallet {
        return try await Self.getModularWalletAddress(
            transport: transport,
            hexPublicKey: owner.getAddress(),
            version: version,
            name: name
        )
    }

    func signAndWrap(
        hash: String,
        hasUserOpGas: Bool
    ) async throws -> String {
        let targetHash = hasUserOpGas ? Utils.hashMessage(hex: hash) : hash
        let signResult = try await owner.sign(messageHash: targetHash)

        let encodePacked = encodePackedForSignature(
            signResult: signResult,
            publicKey: owner.getAddress(),
            hasUserOpGas: hasUserOpGas
        )
        
        return encodePacked
    }
}

extension WebAuthnCircleSmartAccountDelegate {

    // MARK: Internal Usage

    static func getModularWalletAddress(
        transport: ModularTransport,
        hexPublicKey: String,
        version: String,
        name: String? = nil
    ) async throws -> ModularWallet {
        let (publicKeyX, publicKeyY) = Self.extractXYFromCOSE(hexPublicKey)
        let request = GetAddressReq(
            scaConfiguration: ScaConfiguration(
                initialOwnershipConfiguration: .init(
                    ownershipContractAddress: nil,
                    weightedMultiSig: .init(
                        owners: nil,
                        webauthnOwners: [.init(publicKeyX: publicKeyX.description,
                                               publicKeyY: publicKeyY.description,
                                               weight: OWNER_WEIGHT)],
                        thresholdWeight: THRESHOLD_WEIGHT)
                ),
                scaCore: version,
                initCode: nil),
            metadata: .init(name: name)
        )

        let wallet = try await transport.getAddress(
            transport: transport,
            req: request
        )

        return wallet
    }

    /// Remove the private access control for unit testing
    func encodePackedForSignature(
        signResult: SignResult,
        publicKey: String,
        hasUserOpGas: Bool
    ) -> String {
        let DYNAMIC_POSITION = 65
        let pubKey = Self.extractXYFromCOSE(publicKey)
        let sender = Self.getSender(x: pubKey.0, y: pubKey.1)

        let formattedSender = Self.getFormattedSender(sender: sender)
        let sigType: UInt8 = hasUserOpGas ? SIG_TYPE_SECP256R1_DIGEST : SIG_TYPE_SECP256R1
        let sigBytes = encodeWebAuthnSigDynamicPart(signResult: signResult)

        let encoded = Utils.encodePacked([
            formattedSender,
            /// dynamicPos
            /// 32-bytes public key onchain id
            /// 32-bytes webauth, signature and public key position
            /// 1-byte signature type
            /// https://github.com/circlefin/buidl-wallet-contracts/blob/7388395fac2ac8bcd19af9a1caaac5df3c4813f2/docs/Smart_Contract_Signatures_Encoding.md#sigtype--2
            DYNAMIC_POSITION,
            sigType,
            sigBytes.count,
            sigBytes
        ]).addHexPrefix()

        return encoded
    }

    private func encodeWebAuthnSigDynamicPart(signResult: SignResult) -> Data {
        guard let (rData, sData) = Utils.extractRSFromDER(signResult.signature) else {
            logger.passkeyAccount.notice("Can't extract the r, s from a DER-encoded ECDSA signature")
            return .init()
        }

        let (r, s) = (BigUInt(rData), BigUInt(sData))

        let encoded = Self.encodeParametersWebAuthnSigDynamicPart(
            authenticatorDataString: signResult.webAuthn.authenticatorData,
            clientDataJSON: signResult.webAuthn.clientDataJSON,
            challengeIndex: signResult.webAuthn.challengeIndex,
            typeIndex: signResult.webAuthn.typeIndex,
            userVerificationRequired: signResult.webAuthn.userVerificationRequired,
            r: r,
            s: s
        )

        return encoded
    }

    static func encodeParametersWebAuthnSigDynamicPart(
        authenticatorDataString: String,    // Hex
        clientDataJSON: String,             // Base64URL decoded
        challengeIndex: Int,
        typeIndex: Int,
        userVerificationRequired: Bool,
        r: BigUInt,
        s: BigUInt
    ) -> Data {
        let types: [ABI.Element.ParameterType] = [
            .tuple(types: [
                .tuple(types: [
                    .dynamicBytes,
                    .string,
                    .uint(bits: 256),
                    .uint(bits: 256),
                    .bool]),
                .uint(bits: 256),
                .uint(bits: 256)
            ])
        ]

        var authenticatorData = [UInt8]()
        if let _authenticatorData = try? HexUtils.hexToBytes(hex: authenticatorDataString) {
            authenticatorData = _authenticatorData
        }

        let values: [Any] = [
            [
                [
                    authenticatorData,
                    clientDataJSON,
                    BigUInt(challengeIndex),
                    BigUInt(typeIndex),
                    userVerificationRequired
                ],
                r,
                s
            ]
        ]

        var encoded = Data()
        if let _encoded = ABIEncoder.encode(types: types, values: values) {
            encoded = _encoded
        }

        return encoded
    }

    static func extractXYFromCOSE(_ keyHex: String) -> (BigUInt, BigUInt) {
        let xy = Self.extractXYFromCOSEBytes(keyHex)
        return (BigUInt(Data(xy.0)), BigUInt(Data(xy.1)))
    }

    static func extractXYFromCOSEBytes(_ keyHex: String) -> ([UInt8], [UInt8]) {

        guard let bytes = try? HexUtils.hexToBytes(hex: keyHex) else {
            logger.passkeyAccount.error("Failed to decode the publicKey (COSE_Key format) hex string into UInt8 array.")
            return (.init(), .init())
        }

        // EC2 key type
        guard bytes.count == 77 else {
            logger.passkeyAccount.error("Insufficient bytes length; does not comply with COSE Key format EC2 key type.")
            return (.init(), .init())
        }

        let offset = 10

        let x = Array(bytes[offset..<(offset + 32)])
        let y = Array(bytes[(offset + 32 + 3)..<(offset + 64 + 3)])

        return (x, y)
    }

    static func getSender(x: BigUInt, y: BigUInt) -> String {
        let encoded = encodeParametersGetSender(x, y)
        let hash = encoded.sha3(.keccak256)
        return HexUtils.dataToHex(hash)
    }

    static func encodeParametersGetSender(_ x: BigUInt, _ y: BigUInt) -> Data {
        let types: [ABI.Element.ParameterType] = [
            .uint(bits: 256),
            .uint(bits: 256)
        ]
        let values = [x, y]

        let encoded = ABIEncoder.encode(types: types, values: values) ?? Data()

        return encoded
    }

    static func getFormattedSender(sender: String) -> [UInt8] {
        func slice(value: String,
                   start: Int? = nil,
                   end: Int? = nil,
                   strict: Bool = false) -> String {
            let cleanValue = value.noHexPrefix
            let startIndex = (start ?? 0) * 2
            let endIndex = (end ?? (cleanValue.count / 2)) * 2

            guard startIndex >= 0, endIndex <= cleanValue.count, startIndex <= endIndex else {
                logger.passkeyAccount.notice("Return \"0x\" if indices are invalid")
                return "0x"
            }

            let slicedValue = "0x" + cleanValue[startIndex..<endIndex]

            // This block is never executed because the `strict` parameter is always set to its default value (`false`).
//            if strict {
//                guard slicedValue.range(of: "^0x[0-9a-fA-F]*$", options: .regularExpression) != nil else {
//                    logger.passkeyAccount.notice("Invalid hexadecimal string")
//                    return "0x"
//                }
//            }

            return slicedValue
        }

        let slicedSender = slice(value: sender, start: 2)
        let paddedSlicedSender = slicedSender.noHexPrefix.leftPadding(toLength: 32 * 2, withPad: "0").addHexPrefix()

        guard let formattedSender = try? HexUtils.hexToBytes(hex: paddedSlicedSender) else {
            logger.passkeyAccount.error("Failed to get formatted sender")
            return .init()
        }

        return formattedSender
    }
}
