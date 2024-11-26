//
//  ReadTabsUseCase.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import DataServiceKit
import Foundation
import AutoMockable

/// Read tabs use case.
/// Use cases do not hold any mutable state, so that, any of them can be sendable.
public protocol ReadTabsUseCase: BaseUseCase, AutoMockable, Sendable {
    /// Returns tabs count
    var tabsCount: Int { get async }
    /// Returns selected UUID, could be invalid one which is defined (to handle always not empty condition)
    var selectedId: Tab.ID { get async }
    /// Fetches latest tabs.
    var allTabs: [CoreBrowser.Tab] { get async }
}
