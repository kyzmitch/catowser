//
//  GoogleDNSStrategy.swift
//  catowser
//
//  Created by Andrei Ermoshin on 8/6/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import BrowserNetworking
@preconcurrency import ReactiveSwift
import Combine
import CottonRestKit
import Alamofire

public final class GoogleDNSContext: RestClientContext {
    public typealias Response = GoogleDNSOverJSONResponse
    public typealias Server = GoogleDnsServer
    public typealias ReachabilityAdapter = AlamofireReachabilityAdaptee<Server>
    public typealias Encoder = JSONEncoding
    public typealias Client = RestClient<Server, ReachabilityAdapter, Encoder>

    public let client: Client
    public let rxSubscriber: HttpKitRxSubscriber
    public let subscriber: HttpKitSubscriber

    public init(_ client: Client,
                _ rxSubscriber: HttpKitRxSubscriber,
                _ subscriber: HttpKitSubscriber) {
        self.client = client
        self.rxSubscriber = rxSubscriber
        self.subscriber = subscriber
    }
}

public final class GoogleDNSStrategy: DNSResolvingStrategy {
    public typealias Context = GoogleDNSContext

    private let context: Context

    public init(_ context: Context) {
        self.context = context
    }

    public func domainNameResolvingProducer(_ originalURL: URL) -> SignalProducer<URL, DnsError> {
        context.client.rxResolvedDomainName(in: originalURL, context.rxSubscriber)
    }

    public func domainNameResolvingPublisher(_ originalURL: URL) -> AnyPublisher<URL, DnsError> {
        context.client.resolvedDomainName(in: originalURL, context.subscriber)
            .eraseToAnyPublisher()
    }

    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func domainNameResolvingTask(_ originalURL: URL) async throws -> URL {
        let response = try await context.client.aaResolvedDomainName(in: originalURL)
        return response
    }
}
