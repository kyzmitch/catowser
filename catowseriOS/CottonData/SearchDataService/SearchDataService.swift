//
//  SearchDataService.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Combine
import DataServiceKit

public protocol SearchStrategiesFactoryProtocol: AnyObject {
    func googleDnsResolvingStrategy() -> any DNSResolvingStrategy
    func duckDuckGoSearchStrategy() -> any SearchAutocompleteStrategy
    func googleSearchStrategy() -> any SearchAutocompleteStrategy
}

/// Autocompletion search suggestions and DnS data service.
/// In the future should be internal to the module,
/// and only use cases need to be publicly accessible outside of the module.
/// Also, probably DNS part is for another data service.
public final class SearchDataService: GenericConcurrentDataService<SearchServiceCommand, SearchServiceData, SearchServiceError> {

    private var autocompleteHandler: AnyCancellable?
    private var domainNameResolveHandler: AnyCancellable?
    private let stratsFactory: SearchStrategiesFactoryProtocol
    
    /// Initializer
    public init(
        executionQueue: any DispatchQueueInterface = DispatchQueue.global(),
        responseQueue: any DispatchQueueInterface = DispatchQueue.main,
        stratsFactory: SearchStrategiesFactoryProtocol
    ) {
        self.stratsFactory = stratsFactory
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
        case let .fetchAutocompleteSuggestions(searchEngine, query):
            handleSuggestionsFetch(
                command: command,
                searchEngine: searchEngine,
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
        searchEngine: WebAutoCompletionSource,
        query: String
    ) {
        if case .started(input: let existingRequest) = serviceData.searchSuggestions,
           existingRequest?.query == query {
            finishCommand(command, .failure(.sameSearchQueryAlreadyInProgress))
            return
        }
        if let autocompleteHandler {
            autocompleteHandler.cancel()
        }
        let autocompleteStrategy: any SearchAutocompleteStrategy
        // Could be improved if more search engines need to be added by using subclasses instead of an enum
        switch searchEngine {
        case .google:
            autocompleteStrategy = stratsFactory.googleSearchStrategy()
        case .duckduckgo:
            autocompleteStrategy = stratsFactory.duckDuckGoSearchStrategy()
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
        let dnsResolveStrategy = stratsFactory.googleDnsResolvingStrategy()
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
