//
//  TabsPreviewState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import ViewModelKit

/// Tab previews state
public enum TabsPreviewState<C: TabsPreviewsStateContext>: ViewModelState {
    /// Maybe it is not needed state, but it is required for scalability when some user will have 100 tabs
    case loading
    /// Actual collection for tabs, at least one tab always will be in it
    case tabs(dataSource: [CoreBrowser.Tab], selectedId: UUID?)

    /// Number of items for each state
    public var itemsNumber: Int {
        switch self {
        case .loading:
            return 0
        case .tabs(let box, _):
            return box.count
        }
    }
    
    public typealias Context = C
    public typealias Action = TabsPreviewsAction
    public typealias BaseState = TabsPreviewState
    
    public static func createInitial() -> BaseState {
        .loading
    }
    
    @MainActor public func transitionOn(
        _ action: Action,
        with context: Context?
    ) async throws -> BaseState {
        let nextState: BaseState
        switch action {
        case .load:
            if let info = await context?.load() {
                nextState = .tabs(
                    dataSource: info.tabs,
                    selectedId: info.selectedTabUUID
                )
            } else {
                throw TabsPreviewsError.failToLoad
            }
        case .closeTab(index: let index):
            guard case let .tabs(tabs, selectedId) = self else {
                throw TabsPreviewsError.tabsNotLoadedToClose
            }
            guard let info = try await context?.close(at: index, from: tabs) else {
                throw TabsPreviewsError.nilStateContext
            }
            nextState = .tabs(
                dataSource: info.tabs,
                selectedId: info.selectedTabUUID
            )
        case .select(let tab):
            nextState = self
        case .addDefaultTab:
            nextState = self
        case let .addTab(tab: tab, index: index):
            nextState = self
        }
        return nextState
    }
    
    @MainActor public func transitionOn(
        _ action: Action,
        with context: Context?,
        onComplete: @escaping (Result<BaseState, Error>) -> Void
    ) {
        switch action {
        case .load:
            guard let context else {
                onComplete(.failure(TabsPreviewsError.nilStateContext))
                return
            }
            context.load(onComplete: { info in
                let nextState: TabsPreviewState = .tabs(
                    dataSource: info.tabs,
                    selectedId: info.selectedTabUUID
                )
                onComplete(.success(nextState))
            })
        case .closeTab(index: let index):
            guard case let .tabs(tabs, _) = self else {
                onComplete(.failure(TabsPreviewsError.tabsNotLoadedToClose))
                return
            }
            guard let context else {
                onComplete(.failure(TabsPreviewsError.nilStateContext))
                return
            }
            context.close(at: index, from: tabs) { result in
                switch result {
                case .success(let info):
                    let nextState: TabsPreviewState = .tabs(
                        dataSource: info.tabs,
                        selectedId: info.selectedTabUUID
                    )
                    onComplete(.success(nextState))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        case .select(let tab):
            onComplete(.success(.loading))
        case .addDefaultTab:
            onComplete(.success(.loading))
        case let .addTab(tab: tab, index: index):
            onComplete(.success(.loading))
        }
    }
    
    public static func == (
        lhs: TabsPreviewState<C>,
        rhs: TabsPreviewState<C>
    ) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case let (.tabs(leftDataSource, leftSelectedId), .tabs(rightDataSource, rightSelectedId)):
            return leftSelectedId == rightSelectedId && leftDataSource == rightDataSource
        default:
            return false
        }
    }
}
