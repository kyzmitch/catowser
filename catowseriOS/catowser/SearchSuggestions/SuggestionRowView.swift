//
//  SuggestionRowView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/10/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonViewModels

struct SuggestionRowView: View {
    enum Mode {
        case domain
        case suggestion
    }

    private let value: String
    private let mode: Mode
    /// Selected row is stored in upper view with all suggestions
    @Binding private var isSelected: SuggestionType?

    init(_ value: String, _ mode: Mode, _ isSelected: Binding<SuggestionType?>) {
        self.value = value
        self.mode = mode
        _isSelected = isSelected
    }

    var body: some View {
        Text(value)
            .onTapGesture {
                switch mode {
                case .domain:
                    isSelected = .knownDomain(value)
                case .suggestion:
                    isSelected = .suggestion(value)
                }
            }
    }
}

struct SuggestionRowView_Previews: PreviewProvider {
    static var previews: some View {
        let selected: Binding<SuggestionType?> = .init {
            nil
        } set: { _ in
            //
        }

        SuggestionRowView("example.com", .domain, selected)
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
    }
}
