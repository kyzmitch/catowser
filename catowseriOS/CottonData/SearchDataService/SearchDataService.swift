//
//  SearchDataService.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

/// Autocompletion search suggestions and DnS data service.
/// In the future should be internal to the module,
/// and only use cases need to be publicly accessible outside of the module.
public final class SearchDataService: GenericConcurrentDataService<SearchServiceCommand, SearchServiceData> {
    
    public override init(
        executionQueue: any DispatchQueueInterface = DispatchQueue.global(),
        responseQueue: any DispatchQueueInterface = DispatchQueue.main
    ) {
        super.init(
            executionQueue: executionQueue,
            responseQueue: responseQueue
        )
    }
    public override func handleCommand(
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
