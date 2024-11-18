//
//  WriteTabsUseCaseImpl.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import Foundation

public final class WriteTabsUseCaseImpl: WriteTabsUseCase {
    private let tabsDataService: TabsDataService

    public init(_ tabsDataService: TabsDataService) {
        self.tabsDataService = tabsDataService
    }

    public func add(tab: CoreBrowser.Tab) async {
        _ = await tabsDataService.sendCommand(.addTab(tab))
    }

    public func close(tab: CoreBrowser.Tab) async {
        _ = await tabsDataService.sendCommand(.closeTab(tab))
    }

    public func closeAll() async {
        _ = await tabsDataService.sendCommand(.closeAll)
    }

    public func select(tab: CoreBrowser.Tab) async {
        _ = await tabsDataService.sendCommand(.selectTab(tab))
    }

    public func replaceSelected(_ tabContent: CoreBrowser.Tab.ContentType) async {
        _ = await tabsDataService.sendCommand(.replaceContent(tabContent))
    }
}
