//
//  ViewModelInfos.swift
//  catowser
//
//  Created by Andrey Ermoshin on 27.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonData
import CottonPlugins

/// A simple type to return multiple view models from one function
/// instead of a tuple.
final class ViewModelInfos: Sendable {
    /// Tablet specific view model which has to be initialised in async way earlier
    /// to not do async coordinator start for the tabs
    let allTabsVM: AllTabsViewModel
    /// Top sites UIKit view controller needs that view model and it is async
    let topSitesVM: TopSitesViewModel
    /// Search suggestions view model
    let suggestionsVM: any SearchSuggestionsViewModel
    /// phone tab previews view model needed to make Phone previews coordinator
    /// work without a crash, because View model used to fetch VM before use cases registration
    /// which is not the planned sequence of initialization
    let phoneTabPreviewsVM: TabsPreviewsViewModel
    /// web view model
    let webViewModel: any WebViewModel
    /// Search bar view model
    let searchBarVM: any SearchBarViewModelProtocol
    /// Java script plugins source
    let jsPluginsBuilder: (any JSPluginsSource)
    
    init(
        allTabsVM: AllTabsViewModel,
        topSitesVM: TopSitesViewModel,
        phoneTabPreviewsVM: TabsPreviewsViewModel,
        suggestionsVM: any SearchSuggestionsViewModel,
        webViewModel: any WebViewModel,
        searchBarVM: any SearchBarViewModelProtocol,
        jsPluginsBuilder: (any JSPluginsSource)
    ) {
        self.allTabsVM = allTabsVM
        self.topSitesVM = topSitesVM
        self.phoneTabPreviewsVM = phoneTabPreviewsVM
        self.suggestionsVM = suggestionsVM
        self.webViewModel = webViewModel
        self.searchBarVM = searchBarVM
        self.jsPluginsBuilder = jsPluginsBuilder
    }
}
