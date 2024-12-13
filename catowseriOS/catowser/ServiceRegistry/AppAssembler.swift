//
//  AppAssembler.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonPlugins
import FeatureFlagsKit
import CoreBrowser
import CottonDataServices
import CottonViewModels

/// Central class for application initialization
/// Should be called in App delegate or App coordinator.
@globalActor final class AppAssembler {
    static let shared = StateHolder()
    
    actor StateHolder {
        private let featureManager: FeatureManager.StateHolder
        private let serviceRegistry: ServiceRegistry.StateHolder

        init (
            featureManager: FeatureManager.StateHolder = FeatureManager.shared,
            serviceRegistry: ServiceRegistry.StateHolder = ServiceRegistry.shared
        ) {
            self.featureManager = featureManager
            self.serviceRegistry = serviceRegistry
        }
        
        func configure(
            baseDelegate: BasePluginContentDelegate,
            instagramDelegate: InstagramContentDelegate
        ) async -> AppStartInfo {
            // Register data services and use cases
            await serviceRegistry.registerDataServices()
            await UseCaseRegistry.shared.registerUseCases()
            // Read main settings
            async let uiFramework = featureManager.appUIFrameworkValue()
            async let defaultTabContent = DefaultTabProvider.shared.contentState
            async let observingType = featureManager.observingApiTypeValue()
            // Construct java script plugins
            async let pluginsSource = JSPluginsBuilder()
                .setBase(baseDelegate)
                .setInstagram(instagramDelegate)
            // Init view model factory
            async let viewModelFactory = ViewModelFactory.shared
            let supplementaryData = await (
                pluginsSource: pluginsSource,
                viewModelFactory: viewModelFactory
            )
            // Construct dependencies for the view models
            let webContext = await WebViewContextImpl(pluginsSource)
            let factory = supplementaryData.viewModelFactory
            // Init view models
            async let allTabsVM = factory.allTabsViewModel()
            async let topSitesVM = factory.topSitesViewModel()
            async let suggestionsVM = factory.searchSuggestionsViewModel()
            async let phoneTabPreviewsVM = factory.tabsPreviewsViewModel()
            async let webViewModel = factory.getWebViewModel(
                nil,
                webContext,
                nil
            )
            async let searchBarVM = factory.searchBarViewModel()
            // Get a reference to a data service
            let searchDataService = await serviceRegistry.findDataService(
                (any SearchDataServiceProtocol).self,
                .searchDataServiceKey
            )
            // Wait for all the view models needed for app start
            return await AppStartInfo(
                allTabsVM: allTabsVM,
                topSitesVM: topSitesVM,
                phoneTabPreviewsVM: phoneTabPreviewsVM,
                suggestionsVM: suggestionsVM,
                webViewModel: webViewModel,
                searchBarVM: searchBarVM,
                jsPluginsBuilder: pluginsSource,
                defaultTabContent: defaultTabContent,
                observingType: observingType,
                uiFramework: uiFramework,
                searchDataService: searchDataService
            )
        }
    }
}
