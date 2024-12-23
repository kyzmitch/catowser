//
//  BrowserToolbarAction.swift
//  catowser
//
//  Created by Andrey Ermoshin on 23.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import ViewModelKit

/// Browser toolbar view model actions
public enum BrowserToolbarAction: ViewModelAction {
    /// User tapped forward in toolbar for the web view content
    case goForward
    /// User tapped back in toolbar for the web view content
    case goBack
    /// User tapped reload in toolbar for the web view content, to reload web page
    case reload
    /// Web view notified about new states of the navigation buttons
    case updateNavigation(
        canGoBack: Bool?,
        canGoForward: Bool?
    )
    /// Web view notified about progress of web page loading
    case updateProgress(
        show: Bool?,
        value: Float?
    )
    /// New web page was loaded which means that
    /// the navigation buttons must be updated
    case replaceWebInterface(WebViewNavigatable?)
    
    /// All enum cases
    public static let allCases: [BrowserToolbarAction] = [
        .goForward,
        .goBack,
        .reload,
        .updateNavigation(canGoBack: nil, canGoForward: nil),
        .updateProgress(show: nil, value: nil),
        .replaceWebInterface(nil)
    ]
}
