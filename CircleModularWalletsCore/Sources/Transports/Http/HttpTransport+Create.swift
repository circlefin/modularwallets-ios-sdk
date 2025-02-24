//
//  Copyright (c) 2025, Circle Internet Group, Inc.
//  All rights reserved.
//
//  Circle Internet Group, Inc CONFIDENTIAL
//
//  This file includes unpublished proprietary source code of Circle Internet
//  Group, Inc. The copyright notice above does not
//  evidence any actual or intended publication of such source code. Disclosure
//  of this source code or any related proprietary information is strictly
//  prohibited without the express written permission of Circle Internet Group,
//  Inc.
//

/// Creates an HTTP transport instance.
///
/// - Parameters:
///   - url: The URL for the HTTP transport.
///   - options: The configuration options for the HTTP transport (default is an empty configuration).
///
/// - Returns: The configured HTTP transport instance.
public func http(url: String, options: HttpRpcClientOptions? = nil) -> HttpTransport {
    return .init(url: url, options: options)
}

/// Creates an HTTP transport instance.
///
/// - Parameters:
///   - clientKey: The client key for authorization.
///   - url: The URL for the HTTP transport.
///
/// - Returns: The configured HTTP transport instance.
public func toPasskeyTransport(clientKey: String,
                               url: String = CIRCLE_BASE_URL) -> HttpTransport {
    let options = HttpRpcClientOptions(headers: ["Authorization" : "Bearer \(clientKey)"])
    return .init(url: url, options: options)
}

/// Creates an ModularTransport instance.
///
/// - Parameters:
///   - clientKey: The client key for authorization.
///   - url: The URL for the HTTP transport.
///
/// - Returns: The configured HTTP transport instance.
public func toModularTransport(clientKey: String,
                               url: String) -> ModularTransport {
    return .init(clientKey: clientKey, url: url)
}

/// A specific type of HTTP transport that supports the Modular RPC API.
public class ModularTransport: HttpTransport, ModularRpcApi {

    convenience init(clientKey: String, url: String) {
        let options = HttpRpcClientOptions(headers: ["Authorization" : "Bearer \(clientKey)"])
        self.init(url: url, options: options)
    }
}
