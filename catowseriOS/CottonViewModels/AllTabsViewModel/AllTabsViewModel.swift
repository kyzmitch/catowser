//
//  AllTabsViewModel.swift
//  CottonViewModels
//
//  Created by Andrey Ermoshin on 21.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import Combine
import Foundation
import CoreBrowser
import CottonUseCases

@MainActor public final class AllTabsViewModel: ObservableObject {
    private let writeTabUseCase: WriteTabsUseCase

    public init(_ writeTabUseCase: WriteTabsUseCase) {
        self.writeTabUseCase = writeTabUseCase
    }

    public func addTab(_ tab: CoreBrowser.Tab) {
        Task {
            do {
                try await writeTabUseCase.add(tab: tab)
            } catch {
                print("Fail to add new tab: \(error)")
            }
        }
    }
}
