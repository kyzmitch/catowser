//
//  TabsServiceDataOutput.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 20.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import DataServiceKit
import Foundation

/**
 Tabs service data output/response type.
 */
public enum TabsServiceDataOutput: GenericServiceData, Sendable {
    case tabsCount(Int)
    case selectedTabId(UUID)
    case allTabs([CoreBrowser.Tab])
    case tabAdded
    case tabClosed(UUID?)
    case allTabsClosed
    case tabSelected
    case tabContentReplaced(TabsListError?)
    case tabPreviewUpdated(TabsListError?)
}

extension TabsServiceDataOutput: Equatable {}
