//
//  TabsDataSubject.swift
//  CoreBrowser
//
//  Created by Andrei Ermoshin on 3/17/24.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Foundation
#if canImport(Observation)
import Observation
#endif

/// An interface for the tabs data source for observing
@MainActor public protocol TabsDataSubjectProtocol: AnyObject, Sendable {
    /// An identifier of the selected tab
    var selectedTabId: CoreBrowser.Tab.ID { get set }
    /// An array of all tabs
    var tabs: [Tab] { get set }
    /// The amount of tabs
    var tabsCount: Int { get }
    /// Index of the replaced tab, have to use separate property because tabs array can't provide that info
    var replacedTabIndex: Int? { get set }
    /// Added tab index
    var addedTabIndex: Int? { get set }
}

@available(iOS 17.0, *)
@MainActor @Observable public final class TabsDataSubject: TabsDataSubjectProtocol {
    /// An identifier of the selected tab
    public var selectedTabId: CoreBrowser.Tab.ID
    /// The amount of tabs
    public var tabsCount: Int {
        tabs.count
    }
    /// An array of all tabs
    public var tabs: [Tab] = []
    /// Index of the replaced tab, have to use separate property because tabs array can't provide that info
    public var replacedTabIndex: Int?
    /// Added tab index
    public var addedTabIndex: Int?
    
    /// Init
    public init(
        _ positioning: TabsStatesInterface,
        _ tabs: [Tab] = []
    ) {
        self.selectedTabId = positioning.defaultSelectedTabId
        self.tabs = tabs
    }
}
