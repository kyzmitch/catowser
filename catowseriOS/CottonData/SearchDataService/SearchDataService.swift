//
//  SearchDataService.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

final class SearchDataService: GenericConcurrentDataService<SearchServiceCommand, SearchServiceData> {
    override func handleCommand(
        _ command: Command,
        _ input: ServiceData?,
        _ onComplete: @escaping (Result<ServiceData, any Error>) -> Void
    ) {
        switch command {
        case let .fetchAutocompleteSuggestions(query):
            break
        case let .resolveDomainNameInURL(urlWithDomainName):
            break
        }
    }
}
