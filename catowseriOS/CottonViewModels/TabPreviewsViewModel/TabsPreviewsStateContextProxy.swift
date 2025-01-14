//
//  TabsPreviewsStateContextProxy.swift
//  catowser
//
//  Created by Andrey Ermoshin on 14.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import CoreBrowser

/// Tab previews state context impl proxy
public final class TabsPreviewsStateContextProxy: TabsPreviewsStateContext {
    private let subject: any TabsPreviewsStateContext
    
    init(subject: any TabsPreviewsStateContext) {
        self.subject = subject
    }
    
    public func load() async -> PreviewsInfo {
        await subject.load()
    }
    
    public func close(
        at index: Int,
        from tabs: [CoreBrowser.Tab]
    ) async throws -> PreviewsInfo {
        try await subject.close(at: index, from: tabs)
    }
    
    public func select(_ tab: CoreBrowser.Tab) async throws {
        try await subject.select(tab)
    }
    
    public func addDefaultTab() async throws -> PreviewsInfo {
        try await subject.addDefaultTab()
    }
    
    public func addTab(
        _ tab: CoreBrowser.Tab,
        at index: Int
    ) async throws -> PreviewsInfo {
        try await subject.addTab(tab, at: index)
    }
    
    public func load(onComplete: @escaping (PreviewsInfo) -> Void) {
        subject.load(onComplete: onComplete)
    }
    
    public func close(
        at index: Int,
        from tabs: [CoreBrowser.Tab],
        onComplete: @escaping (Result<PreviewsInfo, TabsPreviewsError>) -> Void
    ) {
        subject.close(at: index, from: tabs, onComplete: onComplete)
    }
    
    public func select(
        _ tab: CoreBrowser.Tab,
        onComplete: @escaping (Result<Void, TabsPreviewsError>) -> Void
    ) {
        subject.select(tab, onComplete: onComplete)
    }
}
