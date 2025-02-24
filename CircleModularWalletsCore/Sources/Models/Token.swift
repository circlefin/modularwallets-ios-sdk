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

public enum PolygonToken: String {
    case USDC
    
    public var chainId: Int {
        return Polygon.chainId
    }
    
    public var name: String {
        return "Polygon_\(self.rawValue)"
    }
}

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

public enum PolygonAmoyToken: String {
    case USDC
    
    public var chainId: Int {
        return PolygonAmoy.chainId
    }
    
    public var name: String {
        return "PolygonAmoy_\(self.rawValue)"
    }
}

public enum ArbitrumSepoliaToken: String {
    case USDC
    
    public var chainId: Int {
        return ArbitrumSepolia.chainId
    }
    
    public var name: String {
        return "ArbitrumSepolia_\(self.rawValue)"
    }
}
