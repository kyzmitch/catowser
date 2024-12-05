//
//  ReadTabsUseCaseImpl.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import Foundation

public final class ReadTabsUseCaseImpl: ReadTabsUseCase {
    private let tabsDataService: any TabsDataServiceProtocol
    private let positioning: TabsStatesInterface

    public init(
        _ tabsDataService: any TabsDataServiceProtocol,
        _ positioning: TabsStatesInterface
    ) {
        self.tabsDataService = tabsDataService
        self.positioning = positioning
    }

    public var tabsCount: Int {
        get async {
            let response = await tabsDataService.sendCommand(.getTabsCount, nil)
            guard case .tabsCount(let value) = response else {
                return 1
            }
            return value
        }
    }

    public var selectedId: Tab.ID {
        get async {
            let response = await tabsDataService.sendCommand(.getSelectedTabId, nil)
            guard case .selectedTabId(let value) = response else {
                return positioning.defaultSelectedTabId
            }
            return value
        }
    }

    public var allTabs: [CoreBrowser.Tab] {
        get async {
            let response = await tabsDataService.sendCommand(.getAllTabs, nil)
            guard case .allTabs(let value) = response else {
                return []
            }
            return value
        }
    }
}
