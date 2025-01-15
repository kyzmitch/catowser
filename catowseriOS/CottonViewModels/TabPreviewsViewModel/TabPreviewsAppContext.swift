//
//  TabPreviewsContext.swift
//  catowser
//
//  Created by Andrey Ermoshin on 15.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonBase
import CoreBrowser

/// A tab previews view model context interface
/// to be able to abstract out application stuff.
public protocol TabPreviewsAppContext: AnyObject, Sendable {
    /// Default tab content
    var contentState: Tab.ContentType { get async }
    /// Remove web view controller for a specific site from the cache
    @MainActor func removeWebView(for site: Site) -> Bool
}
