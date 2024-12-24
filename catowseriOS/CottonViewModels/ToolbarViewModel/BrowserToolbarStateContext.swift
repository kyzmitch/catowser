//
//  BrowserToolbarStateContext.swift
//  catowser
//
//  Created by Andrey Ermoshin on 23.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import ViewModelKit

/// Browser toolbar state context interface
public protocol BrowserToolbarStateContext: StateContext {
    var siteNavigationDelegate: SiteNavigationChangable? { get }
    var siteExternalDelegate: SiteExternalNavigationDelegate? { get }
}

/// Browser toolbar state context
public final class BrowserToolbarStateContextProxy: BrowserToolbarStateContext {
    private let subject: any BrowserToolbarStateContext
    
    init(subject: any BrowserToolbarStateContext) {
        self.subject = subject
    }
    
    public var siteNavigationDelegate: SiteNavigationChangable? {
        subject.siteNavigationDelegate
    }
    
    public var siteExternalDelegate: SiteExternalNavigationDelegate? {
        subject.siteExternalDelegate
    }
}
