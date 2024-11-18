//
//  UseCaseRegistry.swift
//  catowser
//
//  Created by Andrey Ermoshin on 20.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import Foundation
import CoreBrowser
import CottonData

extension String {
    static let googleAutocompleteUseCase = "googleAutocompleteUseCase"
    static let duckDuckGoAutocompleteUseCase = "duckDuckGoAutocompleteUseCase"
    static let googleResolveDnsUseCase = "googleResolveDnsUseCase"
}

@globalActor
final class UseCaseRegistry {
    static let shared = StateHolder()
    
    actor StateHolder {
        private let locator: UseCaseLocator

        init() {
            locator = .init()
        }
        
        func registerUseCases() async {
            await registerTabsUseCases()
            registerSearchAutocompleteUseCases()
            registerDnsResolveUseCases()
        }

        func findUseCase<T>(_ type: T.Type, _ key: String? = nil) -> T {
            // swiftlint:disable:next force_unwrapping
            locator.findService(type, key)!
        }

        /// Have to use async functions and actor to be able to get
        /// a reference to data service and also because this
        /// factory should be a singleton as well
        private func registerTabsUseCases() async {
            let dataService = await TabsDataService.shared
            let readUseCase: ReadTabsUseCase = ReadTabsUseCaseImpl(dataService, DefaultTabProvider.shared)
            locator.registerTyped(readUseCase, of: ReadTabsUseCase.self)
            let writeUseCase: WriteTabsUseCase = WriteTabsUseCaseImpl(dataService)
            locator.registerTyped(writeUseCase, of: WriteTabsUseCase.self)
            let selectedTabUseCase: SelectedTabUseCase = SelectedTabUseCaseImpl(dataService)
            locator.registerTyped(selectedTabUseCase, of: SelectedTabUseCase.self)
        }

        private func registerSearchAutocompleteUseCases() {
            let googleContext = GoogleContext(ServiceRegistry.shared.googleClient,
                                              ServiceRegistry.shared.googleClientRxSubscriber,
                                              ServiceRegistry.shared.googleClientSubscriber)
            let googleStrategy = GoogleAutocompleteStrategy(googleContext)
            let googleUseCase: any AutocompleteSearchUseCase = AutocompleteSearchUseCaseImpl(googleStrategy)
            locator.registerNamed(googleUseCase, .googleAutocompleteUseCase)

            let ddGoContext = DDGoContext(ServiceRegistry.shared.duckduckgoClient,
                                          ServiceRegistry.shared.duckduckgoClientRxSubscriber,
                                          ServiceRegistry.shared.duckduckgoClientSubscriber)
            let ddGoStrategy = DDGoAutocompleteStrategy(ddGoContext)
            let ddGoUseCase: any AutocompleteSearchUseCase = AutocompleteSearchUseCaseImpl(ddGoStrategy)
            locator.registerNamed(ddGoUseCase, .duckDuckGoAutocompleteUseCase)
        }

        private func registerDnsResolveUseCases() {
            /// It is the same context for any site or view model, maybe it makes sense to use only one
            let googleContext = GoogleDNSContext(ServiceRegistry.shared.dnsClient,
                                                 ServiceRegistry.shared.dnsClientRxSubscriber,
                                                 ServiceRegistry.shared.dnsClientSubscriber)

            let googleStrategy = GoogleDNSStrategy(googleContext)
            let googleUseCase: any ResolveDNSUseCase = ResolveDNSUseCaseImpl(googleStrategy)
            locator.registerNamed(googleUseCase, .googleResolveDnsUseCase)
        }
    }
}
