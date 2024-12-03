//
//  StratFactory.swift
//  catowser
//
//  Created by Andrey Ermoshin on 03.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonData

final class StratsFactory: SearchStrategiesFactoryProtocol {
    nonisolated(unsafe) static let shared = StratsFactory()
    private let serviceRegistry: ServiceRegistry.StateHolder

    init(serviceRegistry: ServiceRegistry.StateHolder = ServiceRegistry.shared) {
        self.serviceRegistry = serviceRegistry
    }

    func googleDnsResolvingStrategy() -> any DNSResolvingStrategy {
        let googleContext = GoogleDNSContext(
            serviceRegistry.dnsClient,
            serviceRegistry.dnsClientRxSubscriber,
            serviceRegistry.dnsClientSubscriber
        )
        return GoogleDNSStrategy(googleContext)
    }
    
    func duckDuckGoSearchStrategy() -> any SearchAutocompleteStrategy {
        let ddGoContext = DDGoContext(
            serviceRegistry.duckduckgoClient,
            serviceRegistry.duckduckgoClientRxSubscriber,
            serviceRegistry.duckduckgoClientSubscriber
        )
        return DDGoAutocompleteStrategy(ddGoContext)
    }
    
    func googleSearchStrategy() -> any SearchAutocompleteStrategy {
        let googleContext = GoogleContext(
            serviceRegistry.googleClient,
            serviceRegistry.googleClientRxSubscriber,
            serviceRegistry.googleClientSubscriber
        )
        return GoogleAutocompleteStrategy(googleContext)
    }
}
