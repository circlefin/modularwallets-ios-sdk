//
// Copyright (c) 2024, Circle Internet Group, Inc. All rights reserved.
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

let CIRCLE_DOMAIN_EIP712_Template = """
{
  "types": {
    "CircleWeightedWebauthnMultisigMessage": [
      {"name": "hash", "type": "bytes32"}
    ],
    "EIP712Domain": [
      {"name": "name", "type": "string"},
      {"name": "version", "type": "string"},
      {"name": "chainId", "type": "uint256"},
      {"name": "verifyingContract", "type": "address"}
    ]
  },
  "primaryType": "CircleWeightedWebauthnMultisigMessage",
  "domain": {
    "name": "Weighted Multisig Webauthn Plugin",
    "version": "1.0.0",
    "chainId": $CHAINID,
    "verifyingContract": "$VERIFYINGCONTRACT"
  },
  "message": {
    "hash": "$HASH"
  }
}
"""

public let ABI_ERC20 = "[{\"constant\":true,\"inputs\":[],\"name\":\"name\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_spender\",\"type\":\"address\"},{\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"approve\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"totalSupply\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_from\",\"type\":\"address\"},{\"name\":\"_to\",\"type\":\"address\"},{\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"transferFrom\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"decimals\",\"outputs\":[{\"name\":\"\",\"type\":\"uint8\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"version\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_owner\",\"type\":\"address\"}],\"name\":\"balanceOf\",\"outputs\":[{\"name\":\"balance\",\"type\":\"uint256\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"symbol\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_to\",\"type\":\"address\"},{\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"transfer\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_spender\",\"type\":\"address\"},{\"name\":\"_value\",\"type\":\"uint256\"},{\"name\":\"_extraData\",\"type\":\"bytes\"}],\"name\":\"approveAndCall\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_owner\",\"type\":\"address\"},{\"name\":\"_spender\",\"type\":\"address\"}],\"name\":\"allowance\",\"outputs\":[{\"name\":\"remaining\",\"type\":\"uint256\"}],\"payable\":false,\"type\":\"function\"},{\"inputs\":[{\"name\":\"_initialAmount\",\"type\":\"uint256\"},{\"name\":\"_tokenName\",\"type\":\"string\"},{\"name\":\"_decimalUnits\",\"type\":\"uint8\"},{\"name\":\"_tokenSymbol\",\"type\":\"string\"}],\"type\":\"constructor\"},{\"payable\":false,\"type\":\"fallback\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"name\":\"_from\",\"type\":\"address\"},{\"indexed\":true,\"name\":\"_to\",\"type\":\"address\"},{\"indexed\":false,\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"Transfer\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"name\":\"_owner\",\"type\":\"address\"},{\"indexed\":true,\"name\":\"_spender\",\"type\":\"address\"},{\"indexed\":false,\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"Approval\",\"type\":\"event\"},]"

let CONTRACT_ADDRESS: [String: String] = [
    "token_1": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    "token_2": "0xdac17f958d2ee523a2206206994597c13d831ec7",
    "token_3": "0xb8c77482e45f1f44de1745f52c74426c631bdd52"
]

let STUB_SIGNATURE = "0x0000be58786f7ae825e097256fc83a4749b95189e03e9963348373e9c595b15200000000000000000000000000000000000000000000000000000000000000412200000000000000000000000000000000000000000000000000000000000002400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000006091077742edaf8be2fa866827236532ec2a5547fe2721e606ba591d1ffae7a15c022e5f8fe5614bbf65ea23ad3781910eb04a1a60fae88190001ecf46e5f5680a00000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000001700000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002549960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d9763050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000867b2274797065223a22776562617574686e2e676574222c226368616c6c656e6765223a224b6d62474d316a4d554b57794d6352414c6774553953537144384841744867486178564b6547516b503541222c226f726967696e223a22687474703a2f2f6c6f63616c686f73743a35313733222c2263726f73734f726967696e223a66616c73657d0000000000000000000000000000000000000000000000000000"

/** The Circle Weighted WebAuthn multisig plugin address */
let CIRCLE_WEIGHTED_WEB_AUTHN_MULTISIG_PLUGIN = "0x5a2262d58eB72B84701D6efBf6bB6586C793A65b"

let EIP1271_VALID_SIGNATURE: [UInt8] = [0x16, 0x26, 0xba, 0x7e]
let EIP1271_INVALID_SIGNATURE: [UInt8] = [0xff, 0xff, 0xff, 0xff]

/** The public key own weights. */
let PUBLIC_KEY_OWN_WEIGHT = 1

/** The threshold weight. */
let THRESHOLD_WEIGHT = 1

let MINIMUM_VERIFICATION_GAS_LIMIT = 600_000
let MINIMUM_UNDEPLOY_VERIFICATION_GAS_LIMIT = 2_000_000
