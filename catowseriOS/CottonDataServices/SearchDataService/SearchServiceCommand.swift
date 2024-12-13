//
//  SearchServiceCommand.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Foundation
import CoreBrowser
import DataServiceKit

/// Search data service commands,
/// each command has unique id as well to be able to cache
/// similar commands and do request only once.
public enum SearchServiceCommand: GenericDataServiceCommand {
    /// Search for the suggestions about how to finish the query/prefix text
    case fetchAutocompleteSuggestions(UUID, WebAutoCompletionSource, String)
    /// Search for an IP address of the domain name
    case resolveDomainNameInURL(UUID, URL)
    /// Fetch a search engine information and use it to construct a URL with a suggested phase
    case fetchSearchURL(
        identifier: UUID,
        suggestion: String,
        searchEngineName: WebAutoCompletionSource
    )
    
    public static var allCases: [SearchServiceCommand] {
        // swiftlint:disable:next force_unwrapping
        let dummyURL = URL(string: "www.example.com")!
        return [
            .fetchAutocompleteSuggestions(UUID(), .duckduckgo, ""),
            .resolveDomainNameInURL(UUID(), dummyURL),
            .fetchSearchURL(identifier: UUID(), suggestion: "", searchEngineName: .duckduckgo)
        ]
    }
}
