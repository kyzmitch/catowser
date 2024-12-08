//
//  TabsPreviewsViewModel.swift
//  catowser
//
//  Created by Andrey Ermoshin on 21.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import Foundation
import CoreBrowser
import CottonUseCases

typealias TabsBox = Box<[CoreBrowser.Tab]>

enum TabsPreviewState {
    /// Maybe it is not needed state, but it is required for scalability when some user will have 100 tabs
    case loading
    /// Actual collection for tabs, at least one tab always will be in it
    case tabs(dataSource: TabsBox, selectedId: UUID?)

    var itemsNumber: Int {
        switch self {
        case .loading:
            return 0
        case .tabs(let box, _):
            return box.value.count
        }
    }
}

@MainActor final class TabsPreviewsViewModel {
    @Published var uxState: TabsPreviewState = .loading
    private let readTabUseCase: ReadTabsUseCase
    private let writeTabUseCase: WriteTabsUseCase
    private let tabProvider: DefaultTabProvider.StateHolder

    init(
        _ readTabUseCase: ReadTabsUseCase,
        _ writeTabUseCase: WriteTabsUseCase,
        _ tabProvider: DefaultTabProvider.StateHolder
    ) {
        self.readTabUseCase = readTabUseCase
        self.writeTabUseCase = writeTabUseCase
        self.tabProvider = tabProvider
    }

    func load() {
        Task {
            async let tabs = readTabUseCase.allTabs
            async let selectedTabId = readTabUseCase.selectedId
            uxState = await .tabs(
                dataSource: .init(tabs),
                selectedId: selectedTabId
            )
        }
    }

    func closeTab(at index: Int) {
        Task {
            guard case let .tabs(box, _) = uxState else {
                return
            }
            let tab = box.value.remove(at: index)
            /// Rewrite view model state with the updated box
            uxState = .tabs(
                dataSource: box,
                selectedId: nil
            )
            if let site = tab.site {
                WebViewsReuseManager.shared.removeController(for: site)
            }
            await writeTabUseCase.close(tab: tab)
            let newSelectedId = await readTabUseCase.selectedId
            uxState = .tabs(
                dataSource: box,
                selectedId: newSelectedId
            )
        }
    }
    
    func selectTab(_ tab: CoreBrowser.Tab) {
        Task {
            await writeTabUseCase.select(tab: tab)
            // no need to select anything in the view, because it will be closed
        }
    }
    
    func addTab() {
        Task {
            let contentState = await tabProvider.contentState
            let tab = CoreBrowser.Tab(contentType: contentState)
            await writeTabUseCase.add(tab: tab)
            // now need to re-check selected tab in the view
            async let allNewTabs = readTabUseCase.allTabs
            async let newSelectedId = readTabUseCase.selectedId
            uxState = await .tabs(
                dataSource: TabsBox(allNewTabs),
                selectedId: newSelectedId
            )
        }
    }
}
