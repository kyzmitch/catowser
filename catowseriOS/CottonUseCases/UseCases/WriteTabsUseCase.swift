//
//  WriteTabsUseCase.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import AutoMockable
import CoreBrowser
import DataServiceKit
import Foundation

/// Write tabs use case.
/// Use cases do not hold any mutable state, so that, any of them can be sendable.
public protocol WriteTabsUseCase: BaseUseCase, AutoMockable, Sendable {
    /// Adds tab to memory and storage. CoreBrowser.Tab can be blank or it can contain URL address.
    /// CoreBrowser.Tab will be added no matter what happen, so, function doesn't return any result.
    ///
    /// - Parameter tab: A tab.
    func add(tab: Tab) async
    /// Closes tab.
    func close(tab: Tab) async
    /// Closes all tabs.
    func closeAll() async
    /// Remembers selected tab index. Can fail silently if `tab` is not found in a list.
    func select(tab: Tab) async
    /// Replaces currently active tab by combining two operations
    func replaceSelected(_ tabContent: Tab.ContentType) async
}
