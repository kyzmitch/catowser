//
//  TopSitesAppContext.swift
//  catowser
//
//  Created by Andrey Ermoshin on 16.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import CottonBase

/// Top sites data source or application context
public protocol TopSitesAppContext: AnyObject, Sendable {
    /// Fetches an array of top sites and internally checks for JS setting
    func topSites() async -> [Site]
}
