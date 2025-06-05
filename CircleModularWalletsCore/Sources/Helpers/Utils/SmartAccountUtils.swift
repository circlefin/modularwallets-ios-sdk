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

struct SmartAccountUtils {

    static func getDefaultVerificationGasLimit(client: Client,
                                               deployed: Bool) async -> BigInt? {
        var verificationGasLimit: BigInt = deployed ?
        BigInt(MINIMUM_VERIFICATION_GAS_LIMIT) : BigInt(MINIMUM_UNDEPLOY_VERIFICATION_GAS_LIMIT)

        guard let bundlerClient = client as? BundlerClient,
              client.transport is ModularTransport else {
            logger.transport.error("Client is not BundlerClient / Client transport is not ModularTransport")
            return nil
        }

        guard let result = try? await bundlerClient.getUserOperationGasPrice() else {
            logger.bundler.error("Failed to get gas prices from RPC, falling back to hardcoded values: \(verificationGasLimit)")
            return verificationGasLimit
        }

        if deployed, let deployedVerificationGasLimit = result.deployed {
            verificationGasLimit = deployedVerificationGasLimit
        } else if !deployed, let notDeployedVerificationGasLimit = result.notDeployed {
            verificationGasLimit = notDeployedVerificationGasLimit
        }

        return verificationGasLimit
    }

}
