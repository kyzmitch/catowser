//
//  SearchServiceCommand.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

/// Search data service commands
public enum SearchServiceCommand: GenericDataServiceCommand {
    /// Search for the suggestions about how to finish the query/prefix text
    case fetchAutocompleteSuggestions(WebAutoCompletionSource, String)
    /// Search for an IP address of the domain name
    case resolveDomainNameInURL(URL)
    
    public static var allCases: [SearchServiceCommand] {
        // swiftlint:disable:next force_unwrapping
        let dummyURL = URL(string: "www.example.com")!
        return [
            .fetchAutocompleteSuggestions(.duckduckgo, ""),
            .resolveDomainNameInURL(dummyURL)
        ]
    }
}
