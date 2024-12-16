//
//  SearchBarContext.swift
//  catowser
//
//  Created by Andrey Ermoshin on 16.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser

/// Search bar view model context
public protocol SearchBarContext: AnyObject, Sendable {
    /// Do we need to block the pop-ups
    var blockPopups: Bool { get }
    /// Is JavaScript enabled
    var isJSEnabled: Bool { get async }
    /// Web search auto-completion source
    var webAutocompletionSourceValue: WebAutoCompletionSource { get async }
}
