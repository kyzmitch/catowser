//
//  TabViewContext.swift
//  catowser
//
//  Created by Andrey Ermoshin on 15.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonBase
import CottonDataServices

/// Tab view model context to abstract out some app dependencies
public protocol TabViewModelContext: AnyObject, Sendable {
    /// Observing API method
    var observingApiTypeValue: ObservingApiType { get async }
    /// DNS over HTTPs enabled or nah
    var isDohEnabled: Bool { get async }
    /// Remove a view for a site
    @MainActor @discardableResult func removeController(for site: Site) -> Bool
    /// Provides only local cached URL for favicon, nil if ipAddress is nil.
    func faviconURL(
        _ site: Site,
        _ resolve: Bool
    ) async throws -> URL
    /// Reference to the tabs subject to subscribe for its changes,
    /// only available starting from iOS 17
    @available(iOS 17.0, *)
    var tabsSubject: TabsDataSubject { get async }
}
