//
//  ModuleVMFactory.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonUseCases

/// Factory for the view models in this framework to hide actual implementations
@MainActor public final class ModuleVMFactory {
    private init() { }
    /// Search suggestions view model
    public static func createSearchSuggestionsVM(
        _ autocompleteUseCase: AutocompleteSearchUseCase,
        _ context: SearchViewContext
    ) -> any SearchSuggestionsViewModel {
        SearchSuggestionsViewModelImpl(autocompleteUseCase, context)
    }
}
