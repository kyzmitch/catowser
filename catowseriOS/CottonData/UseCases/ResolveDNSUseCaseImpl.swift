//
//  ResolveDNSUseCaseImpl.swift
//  catowser
//
//  Created by Andrei Ermoshin on 7/29/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
@preconcurrency import ReactiveSwift
import Combine
import CottonRestKit

private extension String {
    static let waitingQueueName: String = .queueNameWith(suffix: "dnsResolvingThrottle")
}

public final class ResolveDNSUseCaseImpl: ResolveDNSUseCase {
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

    public func resolveDomainNameProducer(_ url: URL) -> DNSResolvingProducer {
        #warning("TODO: implement for RX")
        let dummyURL = URL(string: "example.com")
        return DNSResolvingProducer(value: dummyURL!)
        /**
        return strategy.domainNameResolvingProducer(url)
            .observe(on: QueueScheduler.main)
         */
    }

    public func resolveDomainNamePublisher(_ url: URL) -> DNSResolvingPublisher {
        let dataServicePublisher = Deferred {
            Future<SearchServiceData, AppError> { [weak self] promise in
                guard let self else {
                    promise(.failure(AppError.zombieSelf))
                    return
                }
                searchDataService.sendCommand(
                    .resolveDomainNameInURL(url),
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
        #warning("TODO: implement for Concurrency")
        throw AppError.zombieSelf
        /**
        let response = try await strategy.domainNameResolvingTask(url)
        return response
         */
    }
}
