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

public let CIRCLE_BASE_URL = "https://modular-sdk.circle.com/v1/rpc/w3s/buidl"
public let ENTRYPOINT_V07_ADDRESS = "0x0000000071727De22E5E9d8BAf0edAc6f37da032"
public let CIRCLE_SMART_ACCOUNT_VERSION_V1 = "circle_passkey_account_v1"

let CIRCLE_SMART_ACCOUNT_VERSION: [String: String] = [
    CIRCLE_SMART_ACCOUNT_VERSION_V1: "circle_6900_v1",
]

let CONTRACT_ADDRESS: [String: String] = [
    PolygonToken.USDC.name: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
    ArbitrumToken.USDC.name: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
    ArbitrumToken.ARB.name: "0x912CE59144191C1204E64559FE8253a0e49E6548",
    BaseToken.USDC.name: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    OptimismToken.USDC.name: "0x0b2c639c533813f4aa9d7837caf62653d097ff85",
    OptimismToken.OP.name: "0x4200000000000000000000000000000000000042",
    UnichainToken.USDC.name: "0x078D782b760474a361dDA0AF3839290b0EF57AD6",

    PolygonAmoyToken.USDC.name: "0x41e94eb019c0762f9bfcf9fb1e58725bfb0e7582",
    ArbitrumSepoliaToken.USDC.name: "0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d",
    BaseSepoliaToken.USDC.name: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
    OptimismSepoliaToken.USDC.name: "0x5fd84259d66Cd46123540766Be93DFE6D43130D7",
    UnichainSepoliaToken.USDC.name: "0x31d0220469e10c4E71834a79b1f276d740d3768F",
]

let STUB_SIGNATURE = "0x0000be58786f7ae825e097256fc83a4749b95189e03e9963348373e9c595b15200000000000000000000000000000000000000000000000000000000000000412200000000000000000000000000000000000000000000000000000000000002400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000006091077742edaf8be2fa866827236532ec2a5547fe2721e606ba591d1ffae7a15c022e5f8fe5614bbf65ea23ad3781910eb04a1a60fae88190001ecf46e5f5680a00000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000001700000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002549960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d9763050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000867b2274797065223a22776562617574686e2e676574222c226368616c6c656e6765223a224b6d62474d316a4d554b57794d6352414c6774553953537144384841744867486178564b6547516b503541222c226f726967696e223a22687474703a2f2f6c6f63616c686f73743a35313733222c2263726f73734f726967696e223a66616c73657d0000000000000000000000000000000000000000000000000000"

/// The Circle Weighted WebAuthn multisig plugin address
let CIRCLE_WEIGHTED_WEB_AUTHN_MULTISIG_PLUGIN = "0x0000000C984AFf541D6cE86Bb697e68ec57873C8"

/// Constants related to EIP-712 typed data signing for replay protection
/// These values must match the smart contract implementation exactly
struct REPLAY_SAFE_HASH_V1 {
    static let name = "Weighted Multisig Webauthn Plugin"
    static let primaryType = "CircleWeightedWebauthnMultisigMessage"
    static let domainSeparatorType =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
    static let moduleType = "CircleWeightedWebauthnMultisigMessage(bytes32 hash)"
    static let version = "1.0.0"
}

let EIP712_PREFIX = "0x1901"
public let EIP1271_VALID_SIGNATURE: [UInt8] = [0x16, 0x26, 0xba, 0x7e]
let EIP1271_INVALID_SIGNATURE: [UInt8] = [0xff, 0xff, 0xff, 0xff]

/// The public key own weights.
let PUBLIC_KEY_OWN_WEIGHT = 1

/// The threshold weight.
let THRESHOLD_WEIGHT = 1

let MINIMUM_VERIFICATION_GAS_LIMIT = 600_000
let MINIMUM_UNDEPLOY_VERIFICATION_GAS_LIMIT = 1_500_000
let SEPOLIA_MINIMUM_VERIFICATION_GAS_LIMIT = 600_000
let SEPOLIA_MINIMUM_UNDEPLOY_VERIFICATION_GAS_LIMIT = 2_000_000
let MAINNET_MINIMUM_VERIFICATION_GAS_LIMIT = 1_000_000
let MAINNET_MINIMUM_UNDEPLOY_VERIFICATION_GAS_LIMIT = 2_500_000
