//
//  TopSitesViewModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 12/17/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonBase
import CoreBrowser
import CottonUseCases

@MainActor final class TopSitesViewModel: ObservableObject {
    let topSites: [Site]
    private let writeTabUseCase: WriteTabsUseCase

    init(
        _ topSites: [Site],
        _ writeTabUseCase: WriteTabsUseCase
    ) {
        self.topSites = topSites
        self.writeTabUseCase = writeTabUseCase
    }

    func replaceSelected(tabContent: CoreBrowser.Tab.ContentType) {
        Task {
            do {
                try await writeTabUseCase.replaceSelected(tabContent)
            } catch {
                print("Fail to replace current tab: \(error)")
            }
        }
    }
}
