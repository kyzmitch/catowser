//
//  ReadTabsUseCaseImpl.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import CottonDataServices

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
            guard
                case let .finished(output: result) = response.tabsCount,
                case let .success(value) = result
            else {
                return 0
            }
            return value
        }
    }

    public var selectedId: CoreBrowser.Tab.ID {
        get async {
            let response = await tabsDataService.sendCommand(.getSelectedTabId, nil)
            guard
                case let .finished(output: result) = response.selectedTabId,
                case let .success(value) = result
            else {
                return positioning.defaultSelectedTabId
            }
            return value
        }
    }

    public var allTabs: [CoreBrowser.Tab] {
        get async {
            let response = await tabsDataService.sendCommand(.getAllTabs, nil)
            guard
                case let .finished(output: result) = response.allTabs,
                case let .success(value) = result
            else {
                return []
            }
            return value
        }
    }
}
