//
//  ModuleVMFactory.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonBase
import CottonUseCases

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
}
