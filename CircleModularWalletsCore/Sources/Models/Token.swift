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

public enum MainnetToken: String {
    case USDT
    case BNB
    case USDC
    case stETH
    case TONCOIN
    case LINK
    case wstETH
    case SHIB
    case WBTC
    case WETH
    case DOT
    case BlurPool
    case BGB
    case LEO
    case UNI
    case PEPE
    case weETH
    case NEAR
    case USDe
    case USDS
    
    public var chainId: Int {
        return Mainnet.chainId
    }
    
    public var name: String {
        return "\(Mainnet.chainId)_\(self.rawValue)"
    }
}

public enum PolygonToken: String {
    case WETH
    case USDT
    case BNB
    case SOL
    case USDC
    case USDC_e
    case BUSD
    case AVAX
    case LINK
    case SHIB
    case WBTC
    case LEO
    case UNI
    case AAVE
    case CRO
    case RNDR
    case DAI
    case OM
    case FET
    
    public var chainId: Int {
        return Polygon.chainId
    }
    
    public var name: String {
        return "\(Polygon.chainId)_\(self.rawValue)"
    }
}

public enum ArbitrumToken: String {
    case USDT
    case USDC_e
    case USDC
    case LINK
    case wstETH
    case WBTC
    case WETH
    case UNI
    case PEPE
    case USDe
    case DAI
    case ARB
    case ENA
    case cbBTC
    case GRT
    case USD0
    case LDO
    case PYTH
    case ezETH
    case CRV
    
    public var chainId: Int {
        return Arbitrum.chainId
    }
    
    public var name: String {
        return "\(Arbitrum.chainId)_\(self.rawValue)"
    }
}

public enum SepoliaToken: String {
    case USDC
    
    public var chainId: Int {
        return Sepolia.chainId
    }
    
    public var name: String {
        return "\(Sepolia.chainId)_\(self.rawValue)"
    }
}

public enum PolygonAmoyToken: String {
    case USDC
    
    public var chainId: Int {
        return PolygonAmoy.chainId
    }
    
    public var name: String {
        return "\(PolygonAmoy.chainId)_\(self.rawValue)"
    }
}

public enum ArbitrumSepoliaToken: String {
    case USDC
    
    public var chainId: Int {
        return ArbitrumSepolia.chainId
    }
    
    public var name: String {
        return "\(ArbitrumSepolia.chainId)_\(self.rawValue)"
    }
}
