//
//  TabsPreviewsStateContext.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/10/25.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import ViewModelKit

/// Tab previews state context interface
public protocol TabsPreviewsStateContext: StateContext {
    func load() async -> ([CoreBrowser.Tab], UUID?)
}

/// Tab previews state context impl proxy
public final class TabsPreviewsStateContextProxy: TabsPreviewsStateContext {
    private let subject: any TabsPreviewsStateContext
    
    init(subject: any TabsPreviewsStateContext) {
        self.subject = subject
    }
    
    public func load() async -> ([CoreBrowser.Tab], UUID?) {
        await subject.load()
    }
}
