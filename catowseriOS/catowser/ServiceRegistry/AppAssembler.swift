//
//  AppAssembler.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonPlugins
import FeaturesFlagsKit
import CottonData
import CoreBrowser

@globalActor final class AppAssembler {
    static let shared = StateHolder()
    
    actor StateHolder {
        private let featureManager: FeatureManager.StateHolder

        init (
            featureManager: FeatureManager.StateHolder = FeatureManager.shared
        ) {
            self.featureManager = featureManager
        }
        
        func configure(
            baseDelegate: BasePluginContentDelegate,
            instagramDelegate: InstagramContentDelegate
        ) async -> AppStartInfo {
            // Init database for the tabs first
            _ = await TabsDataServiceFactory.shared
            // Register data services and use cases
            await ServiceRegistry.shared.registerDataServices()
            await UseCaseRegistry.shared.registerUseCases()
            // Read main settings
            async let searchProvider = featureManager.webSearchAutoCompleteValue()
            async let uiFramework = featureManager.appUIFrameworkValue()
            async let defaultTabContent = DefaultTabProvider.shared.contentState
            async let observingType = featureManager.observingApiTypeValue()
            async let pluginsSource = JSPluginsBuilder()
                .setBase(baseDelegate)
                .setInstagram(instagramDelegate)
            async let viewModelFactory = ViewModelFactory.shared
            let supplementaryData = await (
                searchProvider: searchProvider,
                pluginsSource: pluginsSource,
                viewModelFactory: viewModelFactory
            )

            let webContext = await WebViewContextImpl(pluginsSource)
            let factory = supplementaryData.viewModelFactory
            // Init view models
            async let allTabsVM = factory.allTabsViewModel()
            async let topSitesVM = factory.topSitesViewModel()
            async let suggestionsVM = factory.searchSuggestionsViewModel(supplementaryData.searchProvider)
            async let phoneTabPreviewsVM = factory.tabsPreviewsViewModel()
            async let webViewModel = factory.getWebViewModel(
                nil,
                webContext,
                nil
            )
            async let searchBarVM = factory.searchBarViewModel()

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
                uiFramework: uiFramework
            )
        }
    }
}
