//
//  WriteTabsUseCaseImpl.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import CottonDataServices

public final class WriteTabsUseCaseImpl: WriteTabsUseCase {
    private let tabsDataService: any TabsDataServiceProtocol

    public init(_ tabsDataService: any TabsDataServiceProtocol) {
        self.tabsDataService = tabsDataService
    }

    public func add(tab: CoreBrowser.Tab) async {
        _ = await tabsDataService.sendCommand(.addTab(tab), nil)
    }

    public func close(tab: CoreBrowser.Tab) async {
        _ = await tabsDataService.sendCommand(.closeTab(tab), nil)
    }

    public func closeAll() async {
        _ = await tabsDataService.sendCommand(.closeAll, nil)
    }

    public func select(tab: CoreBrowser.Tab) async {
        _ = await tabsDataService.sendCommand(.selectTab(tab), nil)
    }

    public func replaceSelected(_ tabContent: CoreBrowser.Tab.ContentType) async {
        _ = await tabsDataService.sendCommand(.replaceContent(tabContent), nil)
    }
}
