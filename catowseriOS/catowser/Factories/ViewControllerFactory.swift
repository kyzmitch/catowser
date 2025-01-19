//
//  ViewControllerFactory.swift
//  catowser
//
//  Created by Andrey Ermoshin on 12.11.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import FeatureFlagsKit
import CoreBrowser
import CottonViewModels

/**
 Tried to make view controller factory generic and depend on one generic parameter which
 would be layout type (phone or tablet), but it doesn't give the benefits which are needed, like
 only specific layout can have specific methods which are not needed on another layout.

 It has to be stored as `any ViewControllerFactory` and info about specific layout
 is erased.

 As a current solution some methods could return nil in concrete factory impl.
 */

/// Declares an interface for operations that create abstract product objects.
/// View controllers factory which doesn't depend on device type (phone or tablet)
@MainActor
protocol ViewControllerFactory: AnyObject {
    func rootViewController<W, S, SB>(
        _ coordinator: AppCoordinator,
        _ startContext: AppStartInfo,
        _ searchSuggestionsVM: S,
        _ webVM: W,
        _ searchBarVM: SB
    ) -> AnyViewController
    where W: WebViewModel, S: SearchSuggestionsViewModel, SB: SearchBarViewModelWithDelegates

    func searchBarViewController(
        _ searchBarDelegate: UISearchBarDelegate?,
        _ uiFramework: UIFrameworkType,
        _ viewModel: SearchBarViewModel
    ) -> SearchBarBaseViewController
    func searchSuggestionsViewController(
        _ delegate: SearchSuggestionsListDelegate?,
        _ viewModel: any SearchSuggestionsViewModel
    ) -> AnyViewController

    func webViewController<C: Navigating>(
        _ coordinator: C?,
        _ viewModel: any WebViewModel,
        _ mode: UIFrameworkType
    ) -> AnyViewController & WebViewNavigatable where C.R == WebContentRoute
    func topSitesViewController<C: Navigating>(
        _ coordinator: C?,
        _ topSitesVM: TopSitesViewModel
    ) -> AnyViewController where C.R == TopSitesRoute
    var blankWebPageViewController: UIViewController { get }
    var loadingProgressViewController: AnyViewController { get }
    func siteMenuViewController<C: Navigating>(
        _ model: MenuViewModel,
        _ coordinator: C
    ) -> UIViewController where C.R == MenuScreenRoute

    // MARK: - layout specific methods with optional results

    /// Convinience property to get a reference without input parameters
    var createdDeviceSpecificSearchBarVC: UIViewController? { get }
    /// Convinience property to get a reference without input parameters
    var createdToolbaViewController: UIViewController? { get }
    /// WIll return nil on Tablet
    func deviceSpecificSearchBarViewController(
        _ searchBarDelegate: UISearchBarDelegate?,
        _ uiFramework: UIFrameworkType,
        _ viewModel: SearchBarViewModel
    ) -> AnyViewController?
    /// Will return nil on Phone
    func deviceSpecificSearchBarViewController(
        _ searchBarDelegate: UISearchBarDelegate?,
        _ downloadDelegate: DownloadPanelPresenter?,
        _ settingsDelegate: GlobalMenuDelegate?,
        _ uiFramework: UIFrameworkType,
        _ viewModel: SearchBarViewModel
    ) -> AnyViewController?
    /// WIll return nil on Tablet. Should re-create tabs every time to update them
    func toolbarViewController<C: Navigating>(
        _ downloadDelegate: DownloadPanelPresenter?,
        _ settingsDelegate: GlobalMenuDelegate?,
        _ coordinator: C?,
        // swiftlint:disable:next line_length
        _ presenter: AnyViewController?
    ) -> UIViewController? where C.R == ToolbarRoute
    /// WIll return nil on Tablet
    func tabsPreviewsViewController<C: Navigating>(
        _ coordinator: C,
        _ viewModel: TabsPreviewsViewModelWithHolder
    ) -> UIViewController? where C.R == TabsScreenRoute
    /// Tablet specific tabs
    func tabsViewController(_ vm: AllTabsViewModel) -> AnyViewController?
    /// Download link tags
    func linkTagsViewController(_ delegate: LinkTagsDelegate?) -> AnyViewController & LinkTagsPresenter
    /// The files grid controller to display links for downloads
    func filesGridViewController() -> AnyViewController & FilesGridPresenter
}

extension ViewControllerFactory {
    func rootViewController<W, S, SB>(
        _ coordinator: AppCoordinator,
        _ startContext: AppStartInfo,
        _ searchSuggestionsVM: S,
        _ webVM: W,
        _ searchBarVM: SB
    ) -> AnyViewController
    where W: WebViewModel, S: SearchSuggestionsViewModel, SB: SearchBarViewModelWithDelegates {
        let vc: AnyViewController
        switch startContext.uiFramework {
        case .uiKit:
            vc = MainBrowserViewController(coordinator)
        case .swiftUIWrapper, .swiftUI:
            vc = MainBrowserV2ViewController(
                coordinator,
                startContext,
                searchSuggestionsVM,
                webVM,
                searchBarVM
            )
        }
        return vc
    }

    func searchBarViewController(
        _ searchBarDelegate: UISearchBarDelegate?,
        _ uiFramework: UIFrameworkType,
        _ viewModel: SearchBarViewModel
    ) -> SearchBarBaseViewController {
        let vc: SearchBarBaseViewController = .init(
            searchBarDelegate,
            uiFramework,
            FeatureManager.shared,
            UIServiceRegistry.shared(),
            viewModel
        )
        return vc
    }

    func searchSuggestionsViewController(
        _ delegate: SearchSuggestionsListDelegate?,
        _ viewModel: any SearchSuggestionsViewModel
    ) -> AnyViewController {
        // It seems it should be computed property
        // to allow app. to use different view model
        // based on current feature flag's value
        let vc: SearchSuggestionsViewController = .init(delegate, viewModel)
        return vc
    }

    func webViewController<C: Navigating>(
        _ coordinator: C?,
        _ viewModel: any WebViewModel,
        _ mode: UIFrameworkType
    ) -> AnyViewController & WebViewNavigatable where C.R == WebContentRoute {
        return WebViewController(coordinator, viewModel, mode)
    }

    func siteMenuViewController<C: Navigating>(
        _ model: MenuViewModel,
        _ coordinator: C
    ) -> UIViewController where C.R == MenuScreenRoute {
        let vc: SiteMenuViewController = .init(model, coordinator)
        return vc
    }

    var loadingProgressViewController: AnyViewController {
        let vc: LoadingProgressViewController = .init()
        return vc
    }

    func linkTagsViewController(
        _ delegate: LinkTagsDelegate?
    ) -> AnyViewController & LinkTagsPresenter {
        let vc = LinkTagsViewController.newFromStoryboard(delegate: delegate)
        return vc
    }

    func filesGridViewController() -> AnyViewController & FilesGridPresenter {
        let vc = FilesGridViewController.newFromStoryboard()
        return vc
    }
}
