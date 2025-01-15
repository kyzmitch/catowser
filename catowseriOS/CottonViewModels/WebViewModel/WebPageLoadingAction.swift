//
//  WebPageLoadingAction.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Simplified view actions for view use
public enum WebPageLoadingAction: Equatable {
    /// Create web view from the scratch
    case recreateView(Bool)
    /// Load URL in the web view
    case load(URLRequest)
    /// Reattach all the observers to the web view
    case reattachViewObservers
    /// Navigate to the native application instead of opening it in web view
    case openApp(URL)
}
