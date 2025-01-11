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
    func close(at index: Int) async
    
    // MARK: - closure based API
    
    func load(onComplete: @escaping (PreviewsInfo) -> Void)
    func close(at index: Int, onComplete: @escaping () -> Void)
}

/// Tab previews state context impl proxy
public final class TabsPreviewsStateContextProxy: TabsPreviewsStateContext {
    private let subject: any TabsPreviewsStateContext
    
    init(subject: any TabsPreviewsStateContext) {
        self.subject = subject
    }
    
    public func load() async -> (PreviewsInfo) {
        await subject.load()
    }
    
    public func close(at index: Int) async {
        
    }
    
    public func load(onComplete: @escaping (PreviewsInfo) -> Void) {
        
    }
    
    public func close(at index: Int, onComplete: @escaping () -> Void) {
        
    }
}
