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

// MARK: Mainnet Tokens

public enum ArbitrumToken: String {
    case USDC
    case ARB

    public var chainId: Int {
        return Arbitrum.chainId
    }
    
    public var name: String {
        return "Arbitrum_\(self.rawValue)"
    }
}

public enum AvalancheToken: String {
    case USDC

    public var chainId: Int {
        return Avalanche.chainId
    }
    
    public var name: String {
        return "Avalanche_\(self.rawValue)"
    }
}

public enum BaseToken: String {
    case USDC

    public var chainId: Int {
        return Base.chainId
    }

    public var name: String {
        return "Base_\(self.rawValue)"
    }
}

public enum OptimismToken: String {
    case USDC
    case OP

    public var chainId: Int {
        return Optimism.chainId
    }

    public var name: String {
        return "Optimism_\(self.rawValue)"
    }
}

public enum PolygonToken: String {
    case USDC
    
    public var chainId: Int {
        return Polygon.chainId
    }
    
    public var name: String {
        return "Polygon_\(self.rawValue)"
    }
}

public enum UnichainToken: String {
    case USDC

    public var chainId: Int {
        return Unichain.chainId
    }

    public var name: String {
        return "Unichain_\(self.rawValue)"
    }
}

// MARK: - Testnet Tokens

public enum ArbitrumSepoliaToken: String {
    case USDC
    
    public var chainId: Int {
        return ArbitrumSepolia.chainId
    }
    
    public var name: String {
        return "ArbitrumSepolia_\(self.rawValue)"
    }
}

public enum AvalancheFujiToken: String {
    case USDC

    public var chainId: Int {
        return AvalancheFuji.chainId
    }
    
    public var name: String {
        return "AvalancheFuji_\(self.rawValue)"
    }
}

public enum BaseSepoliaToken: String {
    case USDC

    public var chainId: Int {
        return BaseSepolia.chainId
    }

    public var name: String {
        return "BaseSepolia_\(self.rawValue)"
    }
}

public enum OptimismSepoliaToken: String {
    case USDC

    public var chainId: Int {
        return OptimismSepolia.chainId
    }

    public var name: String {
        return "OptimismSepolia_\(self.rawValue)"
    }
}

public enum PolygonAmoyToken: String {
    case USDC
    
    public var chainId: Int {
        return PolygonAmoy.chainId
    }
    
    public var name: String {
        return "PolygonAmoy_\(self.rawValue)"
    }
}

public enum UnichainSepoliaToken: String {
    case USDC

    public var chainId: Int {
        return UnichainSepolia.chainId
    }

    public var name: String {
        return "UnichainSepolia_\(self.rawValue)"
    }
}
