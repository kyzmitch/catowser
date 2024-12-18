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
import ViewModelKit

public typealias BaseAllTabsViewModel = BaseViewModel<
    AllTabsState<AllTabsViewModelImpl>,
    AllTabsAction
>

@MainActor public final class AllTabsViewModelImpl: BaseAllTabsViewModel {
    private let writeTabUseCase: WriteTabsUseCase

    public init(_ writeTabUseCase: WriteTabsUseCase) {
        self.writeTabUseCase = writeTabUseCase
        super.init()
    }
    
    public override func sendAction(_ action: Action) throws {
        state = try state.handleAction(action, context: self)
    }
}

extension AllTabsViewModelImpl: AllTabsStateContext {
    public func handleTabAdd(_ tab: CoreBrowser.Tab) {
        Task {
            do {
                try await writeTabUseCase.add(tab: tab)
            } catch {
                print("Fail to add new tab: \(error)")
            }
        }
    }
}
