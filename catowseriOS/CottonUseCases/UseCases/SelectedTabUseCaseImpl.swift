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

    public func setSelectedPreview(_ image: Data?) async {
        _ = await tabsDataService.sendCommand(.updateSelectedTabPreview(image), nil)
    }
}
