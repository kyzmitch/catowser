//
//  TopSitesAppContextImpl.swift
//  catowser
//
//  Created by Andrey Ermoshin on 16.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import CottonBase
import CottonViewModels

final class TopSitesAppContextImpl: TopSitesAppContext {
    private let isJsEnabled: Bool
    private let defaultTabProvider: DefaultTabProvider.StateHolder
    
    init(
        _ isJsEnabled: Bool,
        _ defaultTabProvider: DefaultTabProvider.StateHolder
    ) {
        self.isJsEnabled = isJsEnabled
        self.defaultTabProvider = defaultTabProvider
    }

    func topSites() async -> [Site] {
        return await defaultTabProvider.topSites(isJsEnabled)
    }
}
