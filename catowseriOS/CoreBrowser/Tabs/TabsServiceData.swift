//
//  TabsServiceData.swift
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
public enum TabsServiceData: GenericServiceData, Sendable {
    public init() {
        self = .allTabs([])
    }
    
    case tabsCount(Int)
    case selectedTabId(Tab.ID)
    case allTabs([Tab])
    case tabAdded
    case tabClosed(Tab.ID?)
    case allTabsClosed
    case tabSelected
    case tabContentReplaced(TabsListError?)
    case tabPreviewUpdated(TabsListError?)
}

extension TabsServiceData: Equatable {}
