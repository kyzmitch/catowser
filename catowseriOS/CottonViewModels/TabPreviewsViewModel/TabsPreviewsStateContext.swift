//
//  TabsPreviewsStateContext.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/10/25.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import ViewModelKit

/// Info about the tabs and selected tab
public struct PreviewsInfo {
    let tabs: [CoreBrowser.Tab]
    let selectedTabUUID: UUID?
    
    init(
        _ tabs: [CoreBrowser.Tab],
        _ selectedTabUUID: UUID?
    ) {
        self.tabs = tabs
        self.selectedTabUUID = selectedTabUUID
    }
}

/// Tab previews state context interface
public protocol TabsPreviewsStateContext: StateContext {
    
    // MARK: - concurrent API
    
    func load() async -> PreviewsInfo
    func close(
        at index: Int,
        from tabs: [CoreBrowser.Tab]
    ) async throws -> PreviewsInfo
    func select(_ tab: CoreBrowser.Tab) async throws
    func addDefaultTab() async throws -> PreviewsInfo
    func addTab(
        _ tab: CoreBrowser.Tab,
        at index: Int
    ) async throws -> PreviewsInfo
    
    // MARK: - closure based API
    
    func load(onComplete: @escaping (PreviewsInfo) -> Void)
    func close(
        at index: Int,
        from tabs: [CoreBrowser.Tab],
        onComplete: @escaping (Result<PreviewsInfo, TabsPreviewsError>) -> Void
    )
    func select(
        _ tab: CoreBrowser.Tab,
        onComplete: @escaping (Result<Void, TabsPreviewsError>) -> Void
    )
}
