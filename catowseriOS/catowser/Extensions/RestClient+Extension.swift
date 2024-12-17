//
//  RestClient+Extension.swift
//  catowser
//
//  Created by Andrey Ermoshin on 16.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import CottonRestKit
import CottonNetworking

/// Local rest client extension with `URLDomainNameResolve` interface
/// because `CoreBrowser` doesn't know anything about rest clients
extension RestClient: @retroactive URLDomainNameResolve where Server == GoogleDnsServer {
    public func resolvedDomainName(in url: URL) async throws -> URL {
        try await aaResolvedDomainName(in: url)
    }
}
