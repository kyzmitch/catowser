//
//  DuckDuckGoSearchEndpoint+AsyncAwait.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 6/21/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import Foundation

#if swift(>=5.5)

import CottonRestKit

extension RestClient where Server == DuckDuckGoServer {
    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func aaDuckDuckGoSuggestions(for text: String) async throws -> DDGoSuggestionsResponse {
        let endpoint: DDGoSuggestionsEndpoint = try .duckduckgoSuggestions(query: text)
        let adapter: AlamofireHTTPAdaptee<DDGoSuggestionsResponse, DuckDuckGoServer> = .init(.asyncAwaitConcurrency)
        return try await self.aaMakePublicRequest(for: endpoint, transport: adapter)
    }
}

#endif
