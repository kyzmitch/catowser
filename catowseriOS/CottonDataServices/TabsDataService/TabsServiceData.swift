//
//  TabsServiceData.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 20.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import DataServiceKit

public typealias TabIndex = Array<Tab>.Index
public typealias SelectedTabId = Tab.ID

public typealias TabsCountData = CommandExecutionData<Void, Int, TabsListError>
public typealias SelectedTabData = CommandExecutionData<Void, Tab.ID, TabsListError>
public typealias AllTabsData = CommandExecutionData<Void, [Tab], TabsListError>
/// Input can be a newly added tab, but it is passed in a command.
/// Output is the index of the added tab.
public typealias AddTabData = CommandExecutionData<
    Void,
    TabIndex,
    TabsListError
>
/// Input can be a tab id which needs to be closed, but that info is passed in a command.
/// Output is a tab id which is a new selected tab if the closed tab was selected one.
/// New selected tab id output is optional in case if the closed tab wasn't selected and it
/// doesn't change the selection.
public typealias CloseTabData = CommandExecutionData<
    Void,
    SelectedTabId?,
    TabsListError
>
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
    
    /// Need an optimization and use data from `allTabs`
    /// to have a single source of truth, but
    /// at the same time still need to have a state for command execution
    public var tabsCount: TabsCountData
    /// Contains the cache for the selected tab id
    public var selectedTabId: SelectedTabData
    /// Contains the cache for all the tabs
    public var allTabs: AllTabsData
    /// Result of newly added tab
    public var tabAdded: AddTabData
    /// Result of closed tab
    public var tabClosed: CloseTabData
    ///
    public var allTabsClosed: CloseAllTabsData
    public var tabSelected: SelectTabData
    public var tabContentReplaced: ReplaceTabContentData
    public var tabPreviewUpdated: UpdateTabPreviewData
}

// extension TabsServiceData: Equatable {}
