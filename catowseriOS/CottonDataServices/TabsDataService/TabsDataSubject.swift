//
//  TabsDataSubject.swift
//  CottonDataServices
//
//  Created by Andrei Ermoshin on 3/17/24.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

#if canImport(Observation)
import Observation
#endif
import CoreBrowser

/// An interface for the tabs data source for observing
@MainActor public protocol TabsDataSubjectProtocol: AnyObject, Sendable {
    /// An identifier of the selected tab
    var selectedTabId: CoreBrowser.Tab.ID { get set }
    /// An array of all tabs
    var tabs: [CoreBrowser.Tab] { get set }
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
    public var tabs: [CoreBrowser.Tab] = []
    /// Index of the replaced tab, have to use separate property because tabs array can't provide that info
    public var replacedTabIndex: Int?
    /// Added tab index
    public var addedTabIndex: Int?
    
    /// Init
    public init(
        _ positioning: TabsStatesInterface,
        _ tabs: [CoreBrowser.Tab] = []
    ) {
        self.selectedTabId = positioning.defaultSelectedTabId
        self.tabs = tabs
    }
}
