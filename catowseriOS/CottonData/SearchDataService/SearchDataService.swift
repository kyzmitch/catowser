//
//  SearchDataService.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Combine
import DataServiceKit

/// Autocompletion search suggestions and DnS data service.
/// In the future should be internal to the module,
/// and only use cases need to be publicly accessible outside of the module.
/// Also, probably DNS part is for another data service.
public final class SearchDataService: GenericConcurrentDataService<SearchServiceCommand, SearchServiceData, SearchServiceError> {
    
    private let autocompleteStrategy: any SearchAutocompleteStrategy
    private let dnsResolveStrategy: any DNSResolvingStrategy

    private var autocompleteHandler: AnyCancellable?
    private var domainNameResolveHandler: AnyCancellable?
    
    /// Initializer
    public init(
        executionQueue: any DispatchQueueInterface = DispatchQueue.global(),
        responseQueue: any DispatchQueueInterface = DispatchQueue.main,
        autocompleteStrategy: any SearchAutocompleteStrategy,
        dnsResolveStrategy: any DNSResolvingStrategy
    ) {
        self.autocompleteStrategy = autocompleteStrategy
        self.dnsResolveStrategy = dnsResolveStrategy
        super.init(
            executionQueue: executionQueue,
            responseQueue: responseQueue
        )
    }

    public override func handleCommand(
        _ command: Command,
        _ input: ServiceData?
    ) {
        switch command {
        case let .fetchAutocompleteSuggestions(query):
            handleSuggestionsFetch(
                command: command,
                query: query
            )
        case let .resolveDomainNameInURL(urlWithDomainName):
            handleDomainNameResolve(
                command,
                urlWithDomainName
            )
        }
    }
}

// MARK: - private functions

private extension SearchDataService {
    func handleSuggestionsFetch(
        command: Command,
        query: String
    ) {
        if case .started(input: let existingQuery) = serviceData.searchSuggestions, existingQuery == query {
            finishCommand(command, .failure(.sameSearchQueryAlreadyInProgress))
            return
        }
        if let autocompleteHandler {
            autocompleteHandler.cancel()
        }
        autocompleteHandler = autocompleteStrategy.suggestionsPublisher(for: query)
            .map { $0.textResults }
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let failure):
                    self?.finishCommand(command, .failure(.strategyError(failure)))
                }
            }, receiveValue: { [weak self] suggestions in
                guard let self else {
                    return
                }
                serviceData.searchSuggestions = .finished(output: .success(suggestions))
                finishCommand(command, .success(serviceData))
            })
    }
    
    func handleDomainNameResolve(
        _ command: Command,
        _ urlWithDomainName: URL
    ) {
        if let domainNameResolveHandler {
            domainNameResolveHandler.cancel()
        }
        domainNameResolveHandler = dnsResolveStrategy.domainNameResolvingPublisher(urlWithDomainName)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let failure):
                    self?.finishCommand(command, .failure(.strategyError(failure)))
                }
            }, receiveValue: { [weak self] resolvedURL in
                guard let self else {
                    return
                }
                serviceData.domainResolving = .finished(output: .success(resolvedURL))
                finishCommand(command, .success(serviceData))
            })
    }
}
