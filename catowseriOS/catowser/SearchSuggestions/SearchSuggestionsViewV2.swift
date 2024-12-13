//
//  SearchSuggestionsViewV2.swift
//  catowser
//
//  Created by Andrei Ermoshin on 3/29/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonViewModels

struct SearchSuggestionsViewV2<S: SearchSuggestionsViewModel>: View {
    /// Used in waitingForQuery
    private var searchQuery: String
    /// Used when user selects suggestion
    private weak var delegate: SearchSuggestionsListDelegate?
    /// Save currently selected suggestion to be able to observe it
    @State private var selected: SuggestionType?
    /// Used to update the view from loading to suggestions list
    @State private var suggestions: SearchSuggestionsViewState = .waitingForQuery
    /// A view model
    @EnvironmentObject private var viewModel: S

    init(_ searchQuery: String,
         _ delegate: SearchSuggestionsListDelegate?) {
        self.searchQuery = searchQuery
        self.delegate = delegate
        /// Possibly already not needed check
        if !searchQuery.isEmpty {
            suggestions = .waitingForQuery
        }
    }

    var body: some View {
        dynamicView
            .onChange(of: selected) { newValue in
                guard let newValue else {
                    return
                }
                Task {
                    await delegate?.searchSuggestionDidSelect(newValue)
                }
            }
            .onReceive(viewModel.statePublisher, perform: { state in
                suggestions = state
            })
    }

    @ViewBuilder
    private var dynamicView: some View {
        switch suggestions {
        case .waitingForQuery:
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                    .task {
                        /// just asking for a new state, could wait for it as well
                        await viewModel.fetchSuggestions(searchQuery)
                    }
                Spacer()
            }
        case .knownDomainsLoaded(let knownDomains):
            List {
                Section {
                    ForEach(knownDomains) { SuggestionRowView($0, .domain, $selected)}
                } header: {
                    Text(verbatim: suggestions.sectionTitle(section: 0) ?? "Known domains")
                }
            }
        case .everythingLoaded(let knownDomains, let querySuggestions):
            List {
                Section {
                    ForEach(querySuggestions) { SuggestionRowView($0, .suggestion, $selected)}
                } header: {
                    Text(verbatim: suggestions.sectionTitle(section: 1) ?? "Suggestions from search engine")
                }
                Section {
                    ForEach(knownDomains) { SuggestionRowView($0, .domain, $selected)}
                } header: {
                    Text(verbatim: suggestions.sectionTitle(section: 0) ?? "Known domains")
                }
            }
        @unknown default:
            fatalError("Not handle suggestions loading state")
        } // switch
    } // construct view
}
