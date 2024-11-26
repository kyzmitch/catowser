//
//  SearchServiceCommand.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

enum SearchServiceCommand: GenericDataServiceCommand {
    case fetchAutocompleteSuggestions(String)
    case resolveDomainNameInURL(URL)
    
    static var allCases: [SearchServiceCommand] {
        // swiftlint:disable:next force_unwrapping
        let dummyURL = URL(string: "www.example.com")!
        return [
            .fetchAutocompleteSuggestions(""),
            .resolveDomainNameInURL(dummyURL)
        ]
    }
}
