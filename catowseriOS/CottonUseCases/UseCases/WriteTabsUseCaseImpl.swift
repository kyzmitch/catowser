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

    public func add(tab: CoreBrowser.Tab) async throws(AppError) {
        let serviceData = await tabsDataService.sendCommand(.addTab(tab), nil)
        guard case let .finished(result) = serviceData.tabAdded else {
            throw .commandNotFinishedYet
        }
        switch result {
        case .failure(let error):
            throw .tabsServiceError(error)
        case .success:
            return
        }
    }

    public func close(tab: CoreBrowser.Tab) async throws(AppError) -> Tab.ID? {
        let serviceData = await tabsDataService.sendCommand(.closeTab(tab), nil)
        guard case let .finished(result) = serviceData.tabClosed else {
            throw .commandNotFinishedYet
        }
        switch result {
        case .failure(let error):
            throw .tabsServiceError(error)
        case .success(let newSelectedId):
            return newSelectedId
        }
    }

    public func closeAll() async throws(AppError) {
        let serviceData = await tabsDataService.sendCommand(.closeAll, nil)
        guard case let .finished(result) = serviceData.allTabsClosed else {
            throw .commandNotFinishedYet
        }
        switch result {
        case .failure(let error):
            throw .tabsServiceError(error)
        case .success:
            return
        }
    }

    public func select(tab: CoreBrowser.Tab) async throws(AppError) {
        let serviceData = await tabsDataService.sendCommand(.selectTab(tab), nil)
        guard case let .finished(result) = serviceData.tabSelected else {
            throw .commandNotFinishedYet
        }
        switch result {
        case .failure(let error):
            throw .tabsServiceError(error)
        case .success:
            return
        }
    }

    public func replaceSelected(
        _ tabContent: CoreBrowser.Tab.ContentType
    ) async throws(AppError) {
        let serviceData = await tabsDataService.sendCommand(
            .replaceContent(tabContent),
            nil
        )
        guard case let .finished(result) = serviceData.tabContentReplaced else {
            throw .commandNotFinishedYet
        }
        switch result {
        case .failure(let error):
            throw .tabsServiceError(error)
        case .success:
            return
        }
    }
}
