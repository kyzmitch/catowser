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

public final class ResolveDNSUseCaseImpl<Strategy>: ResolveDNSUseCase
where Strategy: DNSResolvingStrategy {
    public let strategy: Strategy

    private let waitingQueue: DispatchQueue
    private let waitingScheduler: QueueScheduler

    public init(_ strategy: Strategy) {
        self.strategy = strategy
        waitingQueue = DispatchQueue(label: .waitingQueueName)
        waitingScheduler = QueueScheduler(
            qos: .userInitiated,
            name: .waitingQueueName,
            targeting: waitingQueue
        )
    }

    public func rxResolveDomainName(_ url: URL) -> DNSResolvingProducer {
        return strategy.domainNameResolvingProducer(url)
            .observe(on: QueueScheduler.main)
    }

    public func cResolveDomainName(_ url: URL) -> DNSResolvingPublisher {
        return strategy.domainNameResolvingPublisher(url)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public func aaResolveDomainName(_ url: URL) async throws -> URL {
        let response = try await strategy.domainNameResolvingTask(url)
        return response
    }
}
