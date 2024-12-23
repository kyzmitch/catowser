//
//  MainBrowserView.swift
//  catowser
//
//  Created by Andrey Ermoshin on 10.12.2022.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CoreBrowser
import FeatureFlagsKit
import CottonDataServices
import CottonViewModels

enum SwiftUIMode {
    /// Re-uses UIKit views
    case compatible
    /// Only new SwiftUI views where possible, web view is still not present
    case full
}

extension UIFrameworkType {
    /// Converts to have only SwiftUI types
    var swiftUIMode: SwiftUIMode {
        switch self {
        case .uiKit:
            // This case is not possible
            // because different view controller is used
            assertionFailure("UIKit is selected in SwiftUI view")
            return .compatible
        case .swiftUIWrapper:
            return .compatible
        case .swiftUI:
            return .full
        }
    }
}

struct MainBrowserView<
    C: ContentCoordinatorsInterface,
    W: WebViewModel,
    S: SearchSuggestionsViewModel,
    SB: SearchBarViewModel
>: View {
    /// Store main view model in this main view to not have generic parameter in phone/tablet views
    @StateObject private var viewModel: MainBrowserViewModel<C>
    /// Browser content view model
    @StateObject private var browserContentVM: BrowserContentViewModel
    /// if User changes it in dev settings, then it is required to restart the app.
    /// Some other old code paths (coordinators and UIKit views) depend on that value,
    /// so, if new value is selected in dev menu, then it could create bugs if app is not restarted.
    /// At the moment app will crash if User selects new UI mode.
    private let mode: SwiftUIMode
    /// All tabs view model which can be injected only in async way, so, has to pass it from outside
    @StateObject private var allTabsVM: AllTabsViewModel
    /// Top sites view model has async dependencies and has to be injected
    @StateObject private var topSitesVM: TopSitesViewModel
    /// Search suggestions view model has async dependencies and has to be injected
    @StateObject private var searchSuggestionsVM: S
    /// Web view model without a specific site
    @StateObject private var webVM: W
    /// Search bar view model
    @StateObject private var searchBarVM: SB
    /// Toolbar model needed by both UI modes
    @StateObject private var toolbarVM: BrowserToolbarViewModel
    /// Default content type is determined in async way, so, would be good to pass it like this
    private let defaultContentType: CoreBrowser.Tab.ContentType

    init(
        _ coordinatorsInterface: C,
        _ uiFrameworkType: UIFrameworkType,
        _ defaultContentType: CoreBrowser.Tab.ContentType,
        _ allTabsVM: AllTabsViewModel,
        _ topSitesVM: TopSitesViewModel,
        _ searchSuggestionsVM: S,
        _ webVM: W,
        _ searchBarVM: SB
    ) {
        let mainVM = MainBrowserViewModel(coordinatorsInterface)
        _viewModel = StateObject(wrappedValue: mainVM)
        let browserVM = BrowserContentViewModel(
            mainVM.jsPluginsBuilder,
            defaultContentType,
            FeatureManager.shared,
            UIServiceRegistry.shared()
        )
        _browserContentVM = StateObject(wrappedValue: browserVM)
        mode = uiFrameworkType.swiftUIMode
        self.defaultContentType = defaultContentType
        _allTabsVM = StateObject(wrappedValue: allTabsVM)
        _topSitesVM = StateObject(wrappedValue: topSitesVM)
        _searchSuggestionsVM = StateObject(wrappedValue: searchSuggestionsVM)
        _webVM = StateObject(wrappedValue: webVM)
        _searchBarVM = StateObject(wrappedValue: searchBarVM)
        _toolbarVM = StateObject(wrappedValue: .init())
    }

    var body: some View {
        Group {
            if isPad {
                TabletView(
                    mode,
                    defaultContentType,
                    webVM,
                    searchSuggestionsVM,
                    searchBarVM
                )
            } else {
                PhoneView(
                    mode,
                    defaultContentType,
                    webVM,
                    searchSuggestionsVM,
                    searchBarVM
                )
            }
        }
        .environment(\.browserContentCoordinators, viewModel.coordinatorsInterface)
        .environmentObject(browserContentVM)
        .environmentObject(allTabsVM)
        .environmentObject(topSitesVM)
        .environmentObject(searchSuggestionsVM)
        .environmentObject(toolbarVM)
        .onAppear {
            Task {
                await ServiceRegistry.shared.tabsService.attach(
                    browserContentVM,
                    notify: true
                )
            }
        }
    }
}
