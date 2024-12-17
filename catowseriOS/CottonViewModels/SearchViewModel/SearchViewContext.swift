//
//  SearchViewContext.swift
//  catowser
//
//  Created by Andrey Ermoshin on 15.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import AutoMockable
import CoreBrowser
import FeatureFlagsKit

/// This is only needed now to not have a direct dependency on FutureManager
public protocol SearchViewContext: AutoMockable, Sendable {
    /// Async API type selected in the app settings
    var appAsyncApiTypeValue: AsyncApiType { get async }
    /// Web search auto-completion source type
    var webAutocompletionSourceValue: WebAutoCompletionSource { get async }
    /// A storage for the known domain names
    var knownDomainsStorage: KnownDomainsSource { get }
}
