//
//  WebPageLoadingAction.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Simplified view actions for view use
public enum WebPageLoadingAction: Equatable {
    case recreateView(Bool)
    case load(URLRequest)
    case reattachViewObservers
    case openApp(URL)
}
