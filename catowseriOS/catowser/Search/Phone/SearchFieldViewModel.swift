//
//  SearchFieldViewModel.swift
//  catowser
//
//  Created by Andrey Ermoshin on 05.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import Combine

/// Search field view model
final class SearchFieldViewModel: ObservableObject {
    @Published var isFocused: Bool
    @Published var submitTapped: Void

    init() {
        self.isFocused = false
        submitTapped = ()
    }
}
