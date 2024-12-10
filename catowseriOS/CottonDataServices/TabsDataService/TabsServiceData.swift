//
//  TabsServiceData.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 20.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import DataServiceKit

public typealias TabsCountData = CommandExecutionData<Void, Int>
public typealias SelectedTabData = CommandExecutionData<Void, Tab.ID>
public typealias AllTabsData = CommandExecutionData<Void, [Tab]>
public typealias AddTabData = CommandExecutionData<Void, Void>
public typealias CloseTabData = CommandExecutionData<Void, Tab.ID>
public typealias CloseAllTabsData = CommandExecutionData<Void, Void>
public typealias SelectTabData = CommandExecutionData<Void, Void>
public typealias ReplaceTabContentData = CommandExecutionData<Void, Void>
public typealias UpdateTabPreviewData = CommandExecutionData<Void, Void>

/**
 Tabs service data output/response type.
 */
public struct TabsServiceData: GenericServiceData, Sendable {
    public init() {
        tabsCount = .notStarted
        selectedTabId = .notStarted
        allTabs = .notStarted
        tabAdded = .notStarted
        tabClosed = .notStarted
        allTabsClosed = .notStarted
        tabSelected = .notStarted
        tabContentReplaced = .notStarted
        tabPreviewUpdated = .notStarted
    }
    
    var tabsCount: TabsCountData
    var selectedTabId: SelectedTabData
    var allTabs: AllTabsData
    var tabAdded: AddTabData
    var tabClosed: CloseTabData
    var allTabsClosed: CloseAllTabsData
    var tabSelected: SelectTabData
    var tabContentReplaced: ReplaceTabContentData
    var tabPreviewUpdated: UpdateTabPreviewData
}

// extension TabsServiceData: Equatable {}
