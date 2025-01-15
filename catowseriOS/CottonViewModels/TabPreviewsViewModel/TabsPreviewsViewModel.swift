//
//  TabsPreviewsViewModel.swift
//  CottonViewModels
//
//  Created by Andrey Ermoshin on 21.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import Foundation
import Combine
import CottonBase
import CoreBrowser
import CottonUseCases
import CottonDataServices
import ViewModelKit

/// Tab previews view model
public typealias TabsPreviewsViewModel = BaseViewModel<
    TabsPreviewState<TabsPreviewsStateContextProxy>,
    TabsPreviewsAction,
    TabsPreviewsStateContextProxy
>

/// Combined base class with additional protocol
public typealias TabsPreviewsViewModelWithHolder = TabsPreviewsViewModel & TabsObserverHolder

/// An interface which allows to add additional capability to view model base class
/// because implementation of view model can't be exposed
@MainActor public protocol TabsObserverHolder {
    var observer: TabsObserver { get }
}

/// Tab previews view model implementation
final public class TabsPreviewsViewModelImpl: TabsPreviewsViewModel {
    private let readTabUseCase: ReadTabsUseCase
    private let writeTabUseCase: WriteTabsUseCase
    private let appContext: TabPreviewsAppContext
    private lazy var proxy: TabsPreviewsStateContextProxy = {
        TabsPreviewsStateContextProxy(subject: self)
    }()

    init(
        _ readTabUseCase: ReadTabsUseCase,
        _ writeTabUseCase: WriteTabsUseCase,
        _ appContext: TabPreviewsAppContext
    ) {
        self.readTabUseCase = readTabUseCase
        self.writeTabUseCase = writeTabUseCase
        self.appContext = appContext
        super.init()
    }
    
    public override var context: Context? {
        proxy
    }
}

// MARK: - TabsObserverHolder

extension TabsPreviewsViewModelImpl: TabsObserverHolder {
    public var observer: any TabsObserver {
        self
    }
}

// MARK: - TabsPreviewsStateContext

extension TabsPreviewsViewModelImpl: TabsPreviewsStateContext {
    public func load() async -> PreviewsInfo {
        async let tabs = readTabUseCase.allTabs
        async let selectedTabId = readTabUseCase.selectedId
        return await PreviewsInfo(tabs, selectedTabId)
    }
    
    public func load(onComplete: @escaping (PreviewsInfo) -> Void) {
        Task {
            async let tabs = readTabUseCase.allTabs
            async let selectedTabId = readTabUseCase.selectedId
            let info = await PreviewsInfo(tabs, selectedTabId)
            onComplete(info)
        }
    }
    
    public func close(
        at index: Int,
        from tabs: [CoreBrowser.Tab]
    ) async throws -> PreviewsInfo {
        var tabs = tabs
        let tab = tabs.remove(at: index)
        /// Rewrite view model state with the updated box
        var info = PreviewsInfo(tabs, nil)
        if let site = tab.site {
            _ = appContext.removeWebView(for: site)
        }
        let newSelectedId = try await writeTabUseCase.close(tab: tab)
        info = PreviewsInfo(tabs, newSelectedId)
        return info
    }
    
    public func close(
        at index: Int,
        from tabs: [CoreBrowser.Tab],
        onComplete: @escaping (Result<PreviewsInfo, TabsPreviewsError>) -> Void
    ) {
        Task {
            do {
                let info = try await close(at: index, from: tabs)
                onComplete(.success(info))
            } catch {
                onComplete(.failure(.useCaseFailure(error)))
            }
        }
    }
    
    public func select(_ tab: Tab) async throws {
        try await writeTabUseCase.select(tab: tab)
    }
    
    public func select(
        _ tab: Tab,
        onComplete: @escaping (Result<Void, TabsPreviewsError>) -> Void
    ) {
        Task {
            do {
                try await writeTabUseCase.select(tab: tab)
                onComplete(.success(()))
            } catch {
                onComplete(.failure(.useCaseFailure(error)))
            }
        }
    }
    
    public func addDefaultTab() async throws -> PreviewsInfo {
        let contentState = await appContext.contentState
        let tab = CoreBrowser.Tab(contentType: contentState)
        try await writeTabUseCase.add(tab: tab)
        // now need to re-check selected tab in the view
        async let allNewTabs = readTabUseCase.allTabs
        async let newSelectedId = readTabUseCase.selectedId
        return await PreviewsInfo(allNewTabs, newSelectedId)
    }
    
    public func addTab(
        _ tab: CoreBrowser.Tab,
        at index: Int
    ) async throws -> PreviewsInfo {
        // No need to call use case, tab is already
        // stored in persistence store, just
        // need to update the in-memory state
        guard case let .tabs(currentTabs, selectedTabId) = state else {
            throw TabsPreviewsError.tabsNotLoadedToInsert
        }
        var tabs = currentTabs
        tabs.insert(tab, at: index)
        return PreviewsInfo(tabs, selectedTabId)
    }
}

// MARK: - TabsObserver

extension TabsPreviewsViewModelImpl: TabsObserver {
    public func tabDidAdd(_ tab: CoreBrowser.Tab, at index: Int) async {
        try? await sendAction(.addTab(tab: tab, index: index))
    }
    
    public func tabDidSelect(
        _ index: Int,
        _ content: CoreBrowser.Tab.ContentType,
        _ identifier: UUID
    ) async {
        // Would be good to handle new selected tab
        // because after inserting/adding new tab
        // in `tabDidAdd` handler, the selection might change
        guard case let .tabs(currentTabs, _) = state else {
            return
        }
        state = .tabs(
            currentTabs,
            identifier
        )
    }
}
