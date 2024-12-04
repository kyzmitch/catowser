//
//  ViewModelFactory.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/21/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonBase
import CottonData
import CoreBrowser
import FeaturesFlagsKit

/// Creates new instances of view models.
/// Depends on feature flags to determine VM configuration/dependencies.
///
/// It doesn't need to be globalActor even tho it is a singleton,
/// because it doesn't hold the state and vm creation is synchronous.
@MainActor
final class ViewModelFactory {
    static let shared: ViewModelFactory = .init()

    private init() {}

    func searchSuggestionsViewModel() async -> any SearchSuggestionsViewModel {
        let vmContext: SearchViewContextImpl = .init()
        let autocompleteUseCase = await UseCaseRegistry.shared.findUseCase(AutocompleteSearchUseCase.self)
        return SearchSuggestionsViewModelImpl(autocompleteUseCase, vmContext)
    }

    func getWebViewModel(
        _ site: Site?,
        _ context: WebViewContext,
        _ siteNavigation: SiteExternalNavigationDelegate?
    ) async -> any WebViewModel {
        async let googleDnsUseCase = UseCaseRegistry.shared.findUseCase(ResolveDNSUseCase.self)
        async let selectTabUseCase = UseCaseRegistry.shared.findUseCase(SelectedTabUseCase.self)
        async let writeUseCase = UseCaseRegistry.shared.findUseCase(WriteTabsUseCase.self)
        return await WebViewModelImpl(
            context,
            googleDnsUseCase,
            selectTabUseCase,
            writeUseCase,
            siteNavigation,
            site
        )
    }

    func tabViewModel(_ tab: CoreBrowser.Tab) async -> TabViewModel {
        async let readUseCase = UseCaseRegistry.shared.findUseCase(ReadTabsUseCase.self)
        async let writeUseCase = UseCaseRegistry.shared.findUseCase(WriteTabsUseCase.self)
        return await TabViewModel(
            tab,
            readUseCase,
            writeUseCase,
            FeatureManager.shared,
            UIServiceRegistry.shared()
        )
    }

    func tabsPreviewsViewModel() async -> TabsPreviewsViewModel {
        async let readUseCase = UseCaseRegistry.shared.findUseCase(ReadTabsUseCase.self)
        async let writeUseCase = UseCaseRegistry.shared.findUseCase(WriteTabsUseCase.self)
        return await TabsPreviewsViewModel(readUseCase, writeUseCase, DefaultTabProvider.shared)
    }

    func allTabsViewModel() async -> AllTabsViewModel {
        let writeUseCase = await UseCaseRegistry.shared.findUseCase(WriteTabsUseCase.self)
        return AllTabsViewModel(writeUseCase)
    }

    func topSitesViewModel() async -> TopSitesViewModel {
        let isJsEnabled = await FeatureManager.shared.boolValue(of: .javaScriptEnabled)
        async let sites = DefaultTabProvider.shared.topSites(isJsEnabled)
        async let writeUseCase = UseCaseRegistry.shared.findUseCase(WriteTabsUseCase.self)
        return await TopSitesViewModel(sites, writeUseCase)
    }
    
    func searchBarViewModel() async -> any SearchBarViewModelProtocol {
        async let writeUseCase = UseCaseRegistry.shared.findUseCase(WriteTabsUseCase.self)
        async let autocompleteUseCase = UseCaseRegistry.shared.findUseCase(AutocompleteSearchUseCase.self)
        return await SearchBarViewModel(
            writeUseCase,
            autocompleteUseCase
        )
    }
}
