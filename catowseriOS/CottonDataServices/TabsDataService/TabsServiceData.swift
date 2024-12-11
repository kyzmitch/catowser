//
//  TabsServiceData.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 20.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import DataServiceKit

public typealias TabsCountData = CommandExecutionData<Void, Int, TabsListError>
public typealias SelectedTabData = CommandExecutionData<Void, Tab.ID, TabsListError>
public typealias AllTabsData = CommandExecutionData<Void, [Tab], TabsListError>
public typealias AddTabData = CommandExecutionData<Void, Void, TabsListError>
public typealias CloseTabData = CommandExecutionData<Void, Tab.ID, TabsListError>
public typealias CloseAllTabsData = CommandExecutionData<Void, Void, TabsListError>
public typealias SelectTabData = CommandExecutionData<Void, Void, TabsListError>
public typealias ReplaceTabContentData = CommandExecutionData<Void, Void, TabsListError>
public typealias UpdateTabPreviewData = CommandExecutionData<Void, Void, TabsListError>

/// Tabs service data output/response type.
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
    
    public var tabsCount: TabsCountData
    public var selectedTabId: SelectedTabData
    public var allTabs: AllTabsData
    public var tabAdded: AddTabData
    public var tabClosed: CloseTabData
    public var allTabsClosed: CloseAllTabsData
    public var tabSelected: SelectTabData
    public var tabContentReplaced: ReplaceTabContentData
    public var tabPreviewUpdated: UpdateTabPreviewData
}

// extension TabsServiceData: Equatable {}
