//
//  TabsDataServiceTests.swift
//  CoreBrowserTests
//
//  Created by Andrei Ermoshin on 4/13/21.
//  Copyright © 2021 Cotton (former Catowser). All rights reserved.
//

import XCTest
import CoreBrowser
import CottonBase

extension UUID {
    static let testId1: UUID = .init(uuid: (1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1))
    static let testId2: UUID = .init(uuid: (0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1))
    static let notPossibleId: UUID = .init(uuid: (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1))
}

class TabsDataServiceTests: XCTestCase {

    let tabsStorageMock: TabsRepositoryMock = .init()

    let tabsStates: TabsStatesMock = .init()

    let selectionStrategyMock: TabSelectionStrategyMock = .init()

    let exampleTabId: UUID = .testId1
    let knownTabId: UUID = .testId2

    let settings: Site.Settings = .init(isPrivate: false,
                                        blockPopups: true,
                                        isJSEnabled: false,
                                        canLoadPlugins: false)

    // swiftlint:disable:next force_try
    let exampleDomainName: DomainName = try! .init(input: "www.example.com")
    // swiftlint:disable:next force_try
    let knownDomainName: DomainName = try! .init(input: "www.known.com")
    lazy var exampleURLInfo: URLInfo = .init(scheme: .https,
                                             path: "foo/bar",
                                             query: nil,
                                             domainName: exampleDomainName,
                                             ipAddress: nil)
    lazy var knownURLInfo: URLInfo = .init(scheme: .https,
                                           path: "bar/bar",
                                           query: nil,
                                           domainName: knownDomainName,
                                           ipAddress: nil)

    lazy var exampleSite: Site = .init(urlInfo: exampleURLInfo,
                                       settings: settings,
                                       faviconData: nil,
                                       searchSuggestion: nil,
                                       userSpecifiedTitle: nil)

    lazy var knownSite: Site = .init(urlInfo: knownURLInfo,
                                     settings: settings,
                                     faviconData: nil,
                                     searchSuggestion: nil,
                                     userSpecifiedTitle: nil)

    func testFailedInit() async throws {
        tabsStates.defaultSelectedTabId = .notPossibleId
        tabsStorageMock.fetchAllTabsThrowableError = TabStorageError.notFound

        let tabsMgr = await TabsDataService(tabsStorageMock, tabsStates, selectionStrategyMock)
        let tabsCountResponse = await tabsMgr.sendCommand(.getTabsCount)
        XCTAssertEqual(tabsCountResponse, TabsServiceData.tabsCount(0))

        let selectedTabIdResponse = await tabsMgr.sendCommand(.getSelectedTabId)
        XCTAssertEqual(selectedTabIdResponse, TabsServiceData.selectedTabId(.notPossibleId))
        let tabsResponse = await tabsMgr.sendCommand(.getAllTabs)
        XCTAssertEqual(tabsResponse, TabsServiceData.allTabs([]))
    }

    func testInit() async throws {
        let tab1: CoreBrowser.Tab = .init(contentType: .site(exampleSite), idenifier: exampleTabId)
        let tab2: CoreBrowser.Tab = .init(contentType: .site(knownSite), idenifier: knownTabId)
        let tabsV1: [CoreBrowser.Tab] = [tab1, tab2]

        tabsStates.defaultSelectedTabId = .notPossibleId
        tabsStorageMock.fetchAllTabsReturnValue = tabsV1
        tabsStorageMock.fetchSelectedTabIdReturnValue = knownTabId
        let tabsMgr = await TabsDataService(tabsStorageMock, tabsStates, selectionStrategyMock)
        let tabsCountResponse = await tabsMgr.sendCommand(.getTabsCount)
        let selectedTabIdResponse = await tabsMgr.sendCommand(.getSelectedTabId)
        XCTAssertEqual(selectedTabIdResponse, TabsServiceData.selectedTabId(knownTabId))
        XCTAssertEqual(tabsCountResponse, TabsServiceData.tabsCount(tabsV1.count))
        let tabsResponse = await tabsMgr.sendCommand(.getAllTabs)
        XCTAssertEqual(tabsResponse, TabsServiceData.allTabs(tabsV1))

        // User selects already selected

        tabsStorageMock.selectTabReturnValue = tab2.id
        _ = await tabsMgr.sendCommand(.selectTab(tab2))
        let nextSelectedTabId2Response = await tabsMgr.sendCommand(.getSelectedTabId)
        XCTAssertEqual(nextSelectedTabId2Response, TabsServiceData.selectedTabId(knownTabId))

        tabsStorageMock.selectTabReturnValue = tab1.id
        _ = await tabsMgr.sendCommand(.selectTab(tab1))
        let nextSelectedTabId1Response = await tabsMgr.sendCommand(.getSelectedTabId)
        XCTAssertEqual(nextSelectedTabId1Response, TabsServiceData.selectedTabId(exampleTabId))
    }
}
