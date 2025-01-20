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

/// Top sites view model
@MainActor public final class TopSitesViewModel: ObservableObject {
    private let appContext: TopSitesAppContext
    private let writeTabUseCase: WriteTabsUseCase

    public init(
        _ appContext: TopSitesAppContext,
        _ writeTabUseCase: WriteTabsUseCase
    ) {
        self.appContext = appContext
        self.writeTabUseCase = writeTabUseCase
    }

    /// Replaces current content of the selected tab
    /// - Parameter tabContent: Content to put in the currently selected tab
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
    
    /// Gives an array of top sites
    public var topSites: [Site] {
        get async {
            await appContext.topSites()
        }
    }
}
