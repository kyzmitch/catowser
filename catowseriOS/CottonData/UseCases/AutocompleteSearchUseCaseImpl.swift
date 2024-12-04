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
import CoreBrowser

private extension String {
    static let waitingQueueName: String = .queueNameWith(suffix: "searchThrottle")
}

/// Web search suggestions (search autocomplete) facade
public final class AutocompleteSearchUseCaseImpl: AutocompleteSearchUseCase {
    private let searchDataService: SearchDataService

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
        let producer: SignalProducer<SearchServiceData, AppError> = .init { [weak self] (observer, lifetime) in
            guard let self = self else {
                observer.send(error: .zombieSelf)
                return
            }
            searchDataService.sendCommand(
                .fetchAutocompleteSuggestions(.duckduckgo, query),
                nil
            ) { result in
                switch result {
                case .failure(let searchError):
                    observer.send(error: .searchDataServiceError(searchError))
                case .success(let serviceData):
                    observer.send(value: serviceData)
                    observer.sendCompleted()
                }
            }
        }
        let source = SignalProducer<String, Never>.init(value: query)
        return source
            .delay(0.5, on: waitingScheduler)
            .flatMap(.latest, { _ -> WebSearchSuggestionsProducer in
                return producer
                    .attemptMap { serviceData in
                        do {
                            return .success(try serviceData.suggestions)
                        } catch {
                            return .failure(.erasedSearchDataServiceError(error))
                        }
                    }
                    
            })
            .observe(on: QueueScheduler.main)
    }

    public func suggestionsPublisher(
        _ source: WebAutoCompletionSource,
        _ query: String
    ) -> WebSearchSuggestionsPublisher {
        let dataServicePublisher = Deferred {
            Future<SearchServiceData, AppError> { [weak self] promise in
                guard let self else {
                    promise(.failure(AppError.zombieSelf))
                    return
                }
                searchDataService.sendCommand(
                    .fetchAutocompleteSuggestions(source, query),
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

    public func fetchSuggestions(
        _ source: WebAutoCompletionSource,
        _ query: String
    ) async throws -> [String] {
        let suggestions: [String] = try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: AppError.zombieSelf)
                return
            }
            searchDataService.sendCommand(
                .fetchAutocompleteSuggestions(source, query),
                nil
            ) { result in
                switch result {
                case .failure(let searchError):
                    continuation.resume(throwing: AppError.searchDataServiceError(searchError))
                case .success(let serviceData):
                    do {
                        continuation.resume(returning: try serviceData.suggestions)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        return suggestions
    }
    
    public func createSearchURL(
        _ source: WebAutoCompletionSource,
        _ suggestion: String
    ) async throws -> URL {
        let searchURL: URL = try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: AppError.zombieSelf)
                return
            }
            searchDataService.sendCommand(
                .fetchSearchURL(
                    suggestion: suggestion,
                    searchEngineName: source
                ),
                nil
            ) { result in
                switch result {
                case .failure(let searchError):
                    continuation.resume(throwing: AppError.searchDataServiceError(searchError))
                case .success(let serviceData):
                    do {
                        continuation.resume(returning: try serviceData.searchURL)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        return searchURL
    }
}
