//
//  ResolveDNSUseCaseImpl.swift
//  catowser
//
//  Created by Andrei Ermoshin on 7/29/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Combine
import CottonDataServices
import Foundation
@preconcurrency import ReactiveSwift

private extension String {
    static let waitingQueueName: String = .queueNameWith(suffix: "dnsResolvingThrottle")
}

public final class ResolveDNSUseCaseImpl: ResolveDNSUseCase {
    private let searchDataService: any SearchDataServiceProtocol

    private let waitingQueue: DispatchQueue
    private let waitingScheduler: QueueScheduler

    public init(_ searchDataService: any SearchDataServiceProtocol) {
        self.searchDataService = searchDataService
        waitingQueue = DispatchQueue(label: .waitingQueueName)
        waitingScheduler = QueueScheduler(
            qos: .userInitiated,
            name: .waitingQueueName,
            targeting: waitingQueue
        )
    }

    public func resolveDomainNameProducer(_ url: URL) -> DNSResolvingProducer {
        let producer: SignalProducer<SearchServiceData, AppError> = .init { [weak self] (observer, lifetime) in
            guard let self = self else {
                observer.send(error: .zombieSelf)
                return
            }
            searchDataService.sendCommand(
                .resolveDomainNameInURL(UUID(), url),
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
        return producer
            .attemptMap { serviceData in
                do {
                    return .success(try serviceData.resolvedURL)
                } catch {
                    return .failure(.erasedSearchDataServiceError(error))
                }
            }
            .observe(on: QueueScheduler.main)
    }

    public func resolveDomainNamePublisher(_ url: URL) -> DNSResolvingPublisher {
        let dataServicePublisher = Deferred {
            Future<SearchServiceData, AppError> { [weak self] promise in
                guard let self else {
                    promise(.failure(AppError.zombieSelf))
                    return
                }
#if swift(>=6)
    nonisolated(unsafe) let promise = promise
#endif
                searchDataService.sendCommand(
                    .resolveDomainNameInURL(UUID(), url),
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

        return dataServicePublisher
            .tryMap { try $0.resolvedURL }
            .mapError { AppError.erasedSearchDataServiceError($0) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public func resolveDomainName(_ url: URL) async throws -> URL {
        let resolvedURL: URL = try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: AppError.zombieSelf)
                return
            }
            searchDataService.sendCommand(
                .resolveDomainNameInURL(UUID(), url),
                nil
            ) { result in
                switch result {
                case .failure(let searchError):
                    continuation.resume(throwing: AppError.searchDataServiceError(searchError))
                case .success(let serviceData):
                    do {
                        continuation.resume(returning: try serviceData.resolvedURL)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        return resolvedURL
    }
}
