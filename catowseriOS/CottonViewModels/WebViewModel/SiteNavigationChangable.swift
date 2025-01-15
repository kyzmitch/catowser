//
//  SiteNavigationChangable.swift
//  catowser
//
//  Created by Andrey Ermoshin on 29.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Site navigation changable interface
@MainActor public protocol SiteNavigationChangable: AnyObject {
    /// Modify navigation back button
    func changeBackButton(to canGoBack: Bool)
    /// Modify navigation forward button
    func changeForwardButton(to canGoForward: Bool)
}
