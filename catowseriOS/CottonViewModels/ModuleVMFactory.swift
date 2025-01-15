//
//  ModuleVMFactory.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonBase
import CoreBrowser
import CottonUseCases
import FeatureFlagsKit
import ViewModelKit

/// Factory for the view models in this framework to hide actual implementations
@MainActor public final class ModuleVMFactory {
    private init() { }
    /// Search suggestions view model
    public static func createSearchSuggestionsVM(
        _ autocompleteUseCase: AutocompleteSearchUseCase,
        _ context: SearchViewContext
    ) -> any SearchSuggestionsViewModel {
        SearchSuggestionsViewModelImpl(autocompleteUseCase, context)
    }
    
    /// Web view model
    public static func createWebViewVM(
        _ context: any WebViewContext,
        _ resolveDnsUseCase: any ResolveDNSUseCase,
        _ selectTabUseCase: SelectedTabUseCase,
        _ writeTabUseCase: WriteTabsUseCase,
        _ siteNavigation: SiteExternalNavigationDelegate?,
        _ site: Site? = nil
    ) -> any WebViewModel {
        WebViewModelImpl(
            context,
            resolveDnsUseCase,
            selectTabUseCase,
            writeTabUseCase,
            siteNavigation,
            site
        )
    }
    
    /// tab view model
    public static func createTabVM(
        _ tab: CoreBrowser.Tab,
        _ readTabUseCase: ReadTabsUseCase,
        _ writeTabUseCase: WriteTabsUseCase,
        _ context: TabViewModelContext,
        _ featureManager: FeatureManager.StateHolder
    ) -> TabViewModel {
        TabViewModelImpl(
            tab,
            readTabUseCase,
            writeTabUseCase,
            context,
            FeatureManager.shared
        )
    }
    
    /// all tabs view model
    public static func createAllTabsVM(
        _ writeTabUseCase: WriteTabsUseCase
    ) -> AllTabsViewModel {
        AllTabsViewModelImpl(writeTabUseCase)
    }
    
    /// Toolbar view model
    public static func createToolbarVM(
        _ appContext: BrowserToolbarViewContext
    ) -> BrowserToolbarViewModel {
        BrowserToolbarViewModelImpl(appContext)
    }
    
    /// Search bar view model
    public static func createSearchBarVM(
        _ writeTabsUseCase: WriteTabsUseCase,
        _ autocompletionUseCase: AutocompleteSearchUseCase,
        _ appContext: SearchBarContext
    ) -> SearchBarViewModelWithDelegates {
        SearchBarViewModelImpl(
            writeTabsUseCase,
            autocompletionUseCase,
            appContext
        )
    }
    
    /// Tab previews view model
    public static func createTabPreviewsVM(
        _ readTabUseCase: ReadTabsUseCase,
        _ writeTabUseCase: WriteTabsUseCase,
        _ appContext: TabPreviewsAppContext
    ) -> TabsPreviewsViewModelWithHolder {
        TabsPreviewsViewModelImpl(readTabUseCase, writeTabUseCase, appContext)
    }
}
