//
//  AutocompleteSearchUseCaseImpl.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/21/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import Foundation
@preconcurrency import ReactiveSwift
import Combine
import CottonRestKit

private extension String {
    static let waitingQueueName: String = .queueNameWith(suffix: "searchThrottle")
}

/// Web search suggestions (search autocomplete) facade
public final class AutocompleteSearchUseCaseImpl: AutocompleteSearchUseCase {
    public let searchDataService: SearchDataService

    private let waitingQueue: DispatchQueue
    private let waitingScheduler: QueueScheduler

    public init(_ searchDataService: SearchDataService) {
        self.searchDataService = searchDataService
        waitingQueue = DispatchQueue(label: .waitingQueueName)
        waitingScheduler = QueueScheduler(
            qos: .userInitiated,
            name: .waitingQueueName,
            targeting: waitingQueue
        )
    }

    public func suggestionsProducer(_ query: String) -> WebSearchSuggestionsProducer {
        #warning("TODO: remove Rx variant or fix it")
        return WebSearchSuggestionsProducer.init(value: [""])
        /**
        let source = SignalProducer<String, Never>.init(value: query)
        return source
            .delay(0.5, on: waitingScheduler)
            .flatMap(.latest, { [weak self] _ -> WebSearchSuggestionsProducer in
                guard let self = self else {
                    return .init(error: .zombieSelf)
                }
                return self.strategy.suggestionsProducer(for: query)
                    .map { $0.textResults }
            })
            .observe(on: QueueScheduler.main)
         */
    }

    public func suggestionsPublisher(_ query: String) -> WebSearchSuggestionsPublisher {
        let dataServicePublisher = Deferred {
            Future<SearchServiceData, AppError> { [weak self] promise in
                guard let self else {
                    promise(.failure(AppError.zombieSelf))
                    return
                }
                searchDataService.sendCommand(
                    .fetchAutocompleteSuggestions(.duckduckgo, query),
                    nil
                ) { result in
                    switch result {
                    case .failure(let searchError):
                        promise(.failure(.searchDataServiceError(searchError)))
                    case .success(let serviceData):
                        promise(.success(serviceData))
                    }
                }
            }
        }.eraseToAnyPublisher()

        let source = Just<String>(query)
        return source
            .delay(for: 0.5, scheduler: waitingQueue)
            .mapError({ (_) -> AppError in
                // workaround to be able to compile case when `Just` has no error type for Failure
                // but it is required to be able to use `flatMap` in next call
                // another option is to use custom publisher which supports non Never Failure type
                return .zombieSelf
            })
            .flatMap({ _ -> WebSearchSuggestionsPublisher in
                return dataServicePublisher
                    .tryMap { try $0.suggestions }
                    .mapError { AppError.erasedSearchDataServiceError($0) }
                    .eraseToAnyPublisher()
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public func fetchSuggestions(_ query: String) async throws -> [String] {
        #warning("TODO: support this API with a new data service")
        throw AppError.zombieSelf
        /**
        let response = try await strategy.suggestionsTask(for: query)
        return response.textResults
         */
    }
}
