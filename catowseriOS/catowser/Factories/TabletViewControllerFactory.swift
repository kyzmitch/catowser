//
//  TabletViewControllerFactory.swift
//  catowser
//
//  Created by Andrey Ermoshin on 12.11.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import FeatureFlagsKit
import UIKit
import CottonViewModels

/// Implements the operations to create tablet layout product objects.
final class TabletViewControllerFactory: ViewControllerFactory {
    private var searchBarVC: UIViewController?
    private var topSitesVC: AnyViewController?
    private var blankVC: UIViewController?

    init() {}

    var createdDeviceSpecificSearchBarVC: UIViewController? {
        return searchBarVC
    }

    var createdToolbaViewController: UIViewController? {
        return nil
    }

    // MARK: - Tablet methods

    func deviceSpecificSearchBarViewController(
        _ searchBarDelegate: UISearchBarDelegate?,
        _ downloadDelegate: DownloadPanelPresenter?,
        _ settingsDelegate: GlobalMenuDelegate?,
        _ uiFramework: UIFrameworkType,
        _ viewModel: SearchBarViewModel
    ) -> AnyViewController? {
        if let existingVC = searchBarVC {
            return existingVC
        }
        searchBarVC = TabletSearchBarViewController(
            searchBarDelegate,
            settingsDelegate,
            downloadDelegate,
            uiFramework,
            viewModel
        )
        return searchBarVC
    }

    func deviceSpecificSearchBarViewController(
        _ searchBarDelegate: UISearchBarDelegate?,
        _ uiFramework: UIFrameworkType,
        _ viewModel: SearchBarViewModel
    ) -> AnyViewController? {
        return nil
    }
    func tabsPreviewsViewController<C: Navigating>(
        _ coordinator: C,
        _ viewModel: TabsPreviewsViewModel
    ) -> UIViewController? where C.R == TabsScreenRoute {
        return nil
    }
    func tabsViewController(_ vm: AllTabsViewModel) -> AnyViewController? {
        let vc = TabsViewController(
            vm,
            FeatureManager.shared,
            UIServiceRegistry.shared()
        )
        return vc
    }
    func toolbarViewController<C: Navigating>(
        _ downloadDelegate: DownloadPanelPresenter?,
        _ settingsDelegate: GlobalMenuDelegate?,
        _ coordinator: C?,
        // swiftlint:disable:next line_length
        _ presenter: AnyViewController?
    ) -> UIViewController? where C.R == ToolbarRoute {
        return nil
    }

    func topSitesViewController<C: Navigating>(
        _ coordinator: C?,
        _ topSitesVM: TopSitesViewModel
    ) -> AnyViewController where C.R == TopSitesRoute {
        if let existingVC = topSitesVC {
            return existingVC
        }
        let bundle = Bundle(for: TopSitesViewController<C>.self)
        let createdVC = TopSitesViewController<C>(
            nibName: "TopSitesViewController",
            bundle: bundle,
            vm: topSitesVM
        )
        createdVC.coordinator = coordinator
        topSitesVC = createdVC
        return createdVC
    }

    var blankWebPageViewController: UIViewController {
        if let existingVC = blankVC {
            return existingVC
        }
        let createdVC: BlankWebPageViewController = .init()
        blankVC = createdVC
        return createdVC
    }
}
