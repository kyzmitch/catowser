//
//  SearchServiceData.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

typealias DomainResolvingData = CommandExecutionData<URL, URL>
typealias SearchSuggestionsData = CommandExecutionData<String, [String]>

public struct SearchServiceData: GenericServiceData {
    var domainResolving: DomainResolvingData = .notStarted
    var searchSuggestions: SearchSuggestionsData = .notStarted
    
    public init() { }
}
