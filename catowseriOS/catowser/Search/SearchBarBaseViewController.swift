//
//  SearchBarBaseViewController.swift
//  catowser
//
//  Created by admin on 19/02/2018.
//  Copyright © 2018 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CoreBrowser
import FeatureFlagsKit

@MainActor protocol SearchBarControllerInterface: AnyObject {
    /* non optional */ func handleAction(_ action: SearchBarAction)
}

final class SearchBarBaseViewController: BaseViewController {
    /// main search bar view
    private let searchBarView: SearchBarLegacyView
    private let featureManager: FeatureManager.StateHolder
    private let uiServiceRegistry: UIServiceRegistry

    init(
        _ searchBarDelegate: UISearchBarDelegate?,
        _ uiFramework: UIFrameworkType,
        _ featureManager: FeatureManager.StateHolder,
        _ uiServiceRegistry: UIServiceRegistry
    ) {
        let customFrame: CGRect
        if case .uiKit = uiFramework {
            customFrame = .zero
        } else {
            customFrame = .init(x: 0, y: 0, width: 0, height: .toolbarViewHeight)
        }
        searchBarView = .init(frame: customFrame, uiFramework: uiFramework)
        searchBarView.delegate = searchBarDelegate
        self.featureManager = featureManager
        self.uiServiceRegistry = uiServiceRegistry
        super.init(nibName: nil, bundle: nil)
        
        Task {
            let observingType = await featureManager.observingApiTypeValue()
            if #available(iOS 17.0, *), observingType.isSystemObservation {
                startTabsObservation()
            } else {
                await TabsDataServiceFactory.shared.attach(self, notify: false)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = searchBarView
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        searchBarView.handleTraitCollectionChange()
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func startTabsObservation() {
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.selectedTabId
        } onChange: {
            Task { [weak self] in
                await self?.handleSelectedTabChange()
            }
        }
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.replacedTabIndex
        } onChange: {
            Task { [weak self] in
                await self?.observeReplacedTab()
            }
        }
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func handleSelectedTabChange() async {
        let subject = uiServiceRegistry.tabsSubject
        let tabId = subject.selectedTabId
        guard let index = subject.tabs
            .firstIndex(where: { $0.id == tabId }) else {
            return
        }
        await tabDidSelect(index, subject.tabs[index].contentType, tabId)
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func observeReplacedTab() async {
        let subject = uiServiceRegistry.tabsSubject
        guard let index = subject.replacedTabIndex else {
            return
        }
        await tabDidReplace(subject.tabs[index], at: index)
    }
}

// MARK: - TabsObserver

extension SearchBarBaseViewController: TabsObserver {
    func tabDidReplace(_ tab: CoreBrowser.Tab, at index: Int) async {
        // this also can be called on non active tab
        // but at the same time it really doesn't make sense
        // to replace site on tab which is not active
        // So, assume that `tab` parameter is currently selected
        // and will replace content which is currently displayed by search bar
        handleAction(.updateView(tab.title, tab.searchBarContent))
    }

    func tabDidSelect(
        _ index: Int,
        _ content: CoreBrowser.Tab.ContentType,
        _ identifier: UUID
    ) async {
        switch content {
        case .site(let site):
            handleAction(.updateView(site.title, site.searchBarContent))
        default:
            handleAction(.clearView)
        }
    }
}

extension SearchBarBaseViewController: SearchBarControllerInterface {
    func handleAction(_ action: SearchBarAction) {
        searchBarView.handleAction(action)
    }
}
