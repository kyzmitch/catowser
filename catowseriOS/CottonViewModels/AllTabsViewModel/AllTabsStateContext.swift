//
//  AllTabsStateContext.swift
//  catowser
//
//  Created by Andrey Ermoshin on 22.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import ViewModelKit

/// All tabs specific state context interface
public protocol AllTabsStateContext: StateContext {
    func handleTabAdd(_ tab: CoreBrowser.Tab)
}

/// All tabs state context which is actually a view model proxy
/// to hide the view model implementation
public final class AllTabsStateContextProxy: AllTabsStateContext {
    private let subject: any AllTabsStateContext
    
    init(subject: any AllTabsStateContext) {
        self.subject = subject
    }
    
    public func handleTabAdd(_ tab: Tab) {
        subject.handleTabAdd(tab)
    }
}
