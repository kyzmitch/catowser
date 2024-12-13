//
//  SelectedTabUseCaseImpl.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import Foundation
import CottonDataServices

public final class SelectedTabUseCaseImpl: SelectedTabUseCase {
    private let tabsDataService: any TabsDataServiceProtocol

    public init(_ tabsDataService: any TabsDataServiceProtocol) {
        self.tabsDataService = tabsDataService
    }

    public func setSelectedPreview(_ image: Data?) async throws(AppError) {
        let serviceData = await tabsDataService.sendCommand(.updateSelectedTabPreview(image), nil)
        guard case let .finished(result) = serviceData.tabPreviewUpdated else {
            throw .commandNotFinishedYet
        }
        do {
            _ = try result.get()
        } catch {
            throw .tabsServiceError(error)
        }
    }
}
