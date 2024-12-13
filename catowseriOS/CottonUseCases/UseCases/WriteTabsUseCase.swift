//
//  WriteTabsUseCase.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import AutoMockable
import CoreBrowser

/// Write tabs use case.
/// Use cases do not hold any mutable state, so that, any of them can be sendable.
public protocol WriteTabsUseCase: BaseUseCase, AutoMockable, Sendable {
    /// Adds tab to memory and storage. CoreBrowser.Tab can be blank or it can contain URL address.
    /// CoreBrowser.Tab will be added no matter what happen, so, function doesn't return any result.
    ///
    /// - Parameter tab: A tab.
    func add(tab: CoreBrowser.Tab) async throws(AppError)
    /// Close a tab
    ///
    /// - Parameter tab: A tab to close
    /// - Returns new selected tab identifier if we closed selected tab and auto-selection happened
    func close(tab: CoreBrowser.Tab) async throws(AppError) -> Tab.ID?
    /// Closes all tabs.
    func closeAll() async throws(AppError)
    /// Remembers selected tab index. Can fail silently if `tab` is not found in a list.
    func select(tab: CoreBrowser.Tab) async throws(AppError)
    /// Replaces currently active tab by combining two operations
    func replaceSelected(
        _ tabContent: CoreBrowser.Tab.ContentType
    ) async throws(AppError)
}
