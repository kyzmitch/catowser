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

/// A tab previews view model context interface
/// to be able to abstract out application stuff.
public protocol TabPreviewsContext: AnyObject, Sendable {
    var contentState: Tab.ContentType { get async }
    @MainActor @discardableResult func removeController(for site: Site) -> Bool
}

/// A typealias for a Box with the tabs
public typealias TabsBox = Box<[CoreBrowser.Tab]>

/// Tab previews state
public enum TabsPreviewState {
    /// Maybe it is not needed state, but it is required for scalability when some user will have 100 tabs
    case loading
    /// Actual collection for tabs, at least one tab always will be in it
    case tabs(dataSource: TabsBox, selectedId: UUID?)

    /// Number of items for each state
    public var itemsNumber: Int {
        switch self {
        case .loading:
            return 0
        case .tabs(let box, _):
            return box.value.count
        }
    }
}

/// Tab previews view model
@MainActor final public class TabsPreviewsViewModel {
    @Published public var uxState: TabsPreviewState = .loading
    private let readTabUseCase: ReadTabsUseCase
    private let writeTabUseCase: WriteTabsUseCase
    private let context: TabPreviewsContext

    public init(
        _ readTabUseCase: ReadTabsUseCase,
        _ writeTabUseCase: WriteTabsUseCase,
        _ context: TabPreviewsContext
    ) {
        self.readTabUseCase = readTabUseCase
        self.writeTabUseCase = writeTabUseCase
        self.context = context
    }

    public func load() {
        Task {
            async let tabs = readTabUseCase.allTabs
            async let selectedTabId = readTabUseCase.selectedId
            uxState = await .tabs(
                dataSource: .init(tabs),
                selectedId: selectedTabId
            )
        }
    }

    public func closeTab(at index: Int) {
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
                context.removeController(for: site)
            }
            do {
                guard let newSelectedId = try await writeTabUseCase.close(tab: tab) else {
                    print("Closed tab wasn't selected")
                    return
                }
                uxState = .tabs(
                    dataSource: box,
                    selectedId: newSelectedId
                )
            } catch {
                print("Fail to close tab: \(error)")
            }
        }
    }
    
    public func selectTab(_ tab: CoreBrowser.Tab) {
        Task {
            do {
                try await writeTabUseCase.select(tab: tab)
            } catch {
                print("Fail to select tab: \(error)")
            }
            // no need to select anything in the view, because it will be closed
        }
    }
    
    public func addTab() {
        Task {
            let contentState = await context.contentState
            let tab = CoreBrowser.Tab(contentType: contentState)
            do {
                try await writeTabUseCase.add(tab: tab)
            } catch {
                print("Fail to add tab: \(error)")
            }
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
