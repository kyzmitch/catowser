//
//  BrowserToolbarViewContext.swift
//  catowser
//
//  Created by Andrey Ermoshin on 23.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// External dependency for the toolbar view model
///
/// Can only be implemented on app side (not inside this framework)
@MainActor public protocol BrowserToolbarViewContext: AnyObject {
    var siteNavigationDelegate: SiteNavigationChangable? { get }
}
