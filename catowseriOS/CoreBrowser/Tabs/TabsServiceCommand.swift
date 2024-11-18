//
//  TabsServiceCommand.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 20.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import DataServiceKit
import Foundation

/**
 Tabs data service commands for the Command design pattern.
 Each command case can carry the input data.
 */
public enum TabsServiceCommand: GenericDataServiceCommand, Sendable {
    case getTabsCount
    case getSelectedTabId
    case getAllTabs
    case addTab(Tab)
    case closeTab(Tab)
    case closeTabWithId(Tab.ID)
    case closeAll
    case selectTab(Tab)
    case replaceContent(Tab.ContentType)
    case updateSelectedTabPreview(Data?)
    
    public static let allCases: [TabsServiceCommand] = [
        .getTabsCount,
        .getSelectedTabId,
        .getAllTabs,
        .addTab(.blank),
        .closeTab(.blank),
        .closeTabWithId(.init()),
        .closeAll,
        .selectTab(.blank),
        .replaceContent(.blank),
        .updateSelectedTabPreview(nil)
    ]
}
