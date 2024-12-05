//
//  UseCaseRegistry.swift
//  catowser
//
//  Created by Andrey Ermoshin on 20.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import DataServiceKit
import Foundation
import CoreBrowser
import CottonData

@globalActor
final class UseCaseRegistry {
    static let shared = StateHolder()
    
    actor StateHolder {
        private let useCaseLocator: UseCaseLocator
        private let serviceRegistry: ServiceRegistry.StateHolder

        init(
            useCaseLocator: UseCaseLocator = UseCaseLocator(),
            serviceRegistry: ServiceRegistry.StateHolder = ServiceRegistry.shared
        ) {
            self.useCaseLocator = useCaseLocator
            self.serviceRegistry = serviceRegistry
        }
        
        func registerUseCases() async {
            await registerTabsUseCases()
            await registerSearchAutocompleteUseCases()
            await registerDnsResolveUseCases()
        }

        func findUseCase<T>(_ type: T.Type, _ key: String? = nil) -> T {
            // swiftlint:disable:next force_unwrapping
            useCaseLocator.findService(type, key)!
        }

        /// Have to use async functions and actor to be able to get
        /// a reference to data service and also because this
        /// factory should be a singleton as well
        private func registerTabsUseCases() async {
            let dataService = await TabsDataServiceFactory.shared
            let readUseCase: ReadTabsUseCase = ReadTabsUseCaseImpl(
                dataService,
                DefaultTabProvider.shared
            )
            useCaseLocator.registerTyped(readUseCase, of: ReadTabsUseCase.self)
            let writeUseCase: WriteTabsUseCase = WriteTabsUseCaseImpl(dataService)
            useCaseLocator.registerTyped(
                writeUseCase,
                of: WriteTabsUseCase.self
            )
            let selectedTabUseCase: SelectedTabUseCase = SelectedTabUseCaseImpl(dataService)
            useCaseLocator.registerTyped(
                selectedTabUseCase,
                of: SelectedTabUseCase.self
            )
        }

        private func registerSearchAutocompleteUseCases() async {
            let searchDataService = await serviceRegistry.findDataService(
                (any SearchDataServiceProtocol).self,
                .searchDataServiceKey
            )
            let googleUseCase: AutocompleteSearchUseCase = AutocompleteSearchUseCaseImpl(searchDataService)
            useCaseLocator.registerTyped(
                googleUseCase,
                of: AutocompleteSearchUseCase.self
            )
        }

        private func registerDnsResolveUseCases() async {
            let searchDataService = await serviceRegistry.findDataService(
                (any SearchDataServiceProtocol).self,
                .searchDataServiceKey
            )
            let googleUseCase: ResolveDNSUseCase = ResolveDNSUseCaseImpl(searchDataService)
            useCaseLocator.registerTyped(
                googleUseCase,
                of: ResolveDNSUseCase.self
            )
        }
    }
}
