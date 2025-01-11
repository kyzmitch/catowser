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
import ViewModelKit

public typealias TabsPreviewsViewModel = BaseViewModel<
    TabsPreviewState<TabsPreviewsStateContextProxy>,
    TabsPreviewsAction,
    TabsPreviewsStateContextProxy
>

/// Tab previews view model
final public class TabsPreviewsViewModelImpl: TabsPreviewsViewModel {
    private let readTabUseCase: ReadTabsUseCase
    private let writeTabUseCase: WriteTabsUseCase
    private let appContext: TabPreviewsAppContext

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
        TabsPreviewsStateContextProxy(subject: self)
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
        /*
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
         */
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
        
    }
    
    public func close(at index: Int) async {
        /*
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
            appContext.removeWebView(for: site)
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
         */
    }
    
    public func close(at index: Int, onComplete: @escaping () -> Void) {
        
    }
}
