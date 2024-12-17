//
//  TopSitesViewModel.swift
//  CottonViewModels
//
//  Created by Andrei Ermoshin on 12/17/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Combine
import CottonBase
import CoreBrowser
import CottonUseCases

@MainActor public final class TopSitesViewModel: ObservableObject {
    public let topSites: [Site]
    private let writeTabUseCase: WriteTabsUseCase

    public init(
        _ topSites: [Site],
        _ writeTabUseCase: WriteTabsUseCase
    ) {
        self.topSites = topSites
        self.writeTabUseCase = writeTabUseCase
    }

    public func replaceSelected(
        tabContent: CoreBrowser.Tab.ContentType
    ) {
        Task {
            do {
                try await writeTabUseCase.replaceSelected(tabContent)
            } catch {
                print("Fail to replace current tab: \(error)")
            }
        }
    }
}
