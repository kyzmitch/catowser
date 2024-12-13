//
//  SearchSuggestionsView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/4/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonViewModels

struct SearchSuggestionsView<S: SearchSuggestionsViewModel>: View {
    private let searchQuery: String
    private weak var delegate: SearchSuggestionsListDelegate?
    private let mode: SwiftUIMode
    @EnvironmentObject private var viewModel: S

    init(_ searchQuery: String,
         _ delegate: SearchSuggestionsListDelegate?,
         _ mode: SwiftUIMode) {
        self.searchQuery = searchQuery
        self.delegate = delegate
        self.mode = mode
    }

    var body: some View {
        switch mode {
        case .compatible:
            SearchSuggestionsLegacyView<S>(searchQuery, delegate)
        case .full:
            SearchSuggestionsViewV2<S>(searchQuery, delegate)
        }
    }
}
