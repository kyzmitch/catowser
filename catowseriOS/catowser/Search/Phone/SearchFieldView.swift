//
//  SearchFieldView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/25/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI

/// Search field view
struct SearchFieldView: View {
    /// Text content, from the super view it is search query
    @Binding private var textContent: String
    /// Determines if keyboard visible or not
    private let showKeyboard: Bool
    /// Determines if need to be focused
    @FocusState private var isFocused: Bool
    /// View model
    @ObservedObject private var vm: SearchFieldViewModel

    init(
        _ textContent: Binding<String>,
        _ showKeyboard: Bool,
        _ vm: SearchFieldViewModel
    ) {
        self.vm = vm
        _textContent = textContent
        self.showKeyboard = showKeyboard
        isFocused = false
    }

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField(.placeholderTextKey, text: $textContent)
                .textInputAutocapitalization(.never)
                .textSelection(.enabled)
                .focused($isFocused)
                .onSubmit {
                    vm.submitTapped = ()
                }
        }
        .onChange(of: isFocused) { vm.isFocused = $0 }
        .onChange(of: showKeyboard) { isFocused = $0 }
    }
}

/// A value type struct from SwiftUICore system module which wasn't sendable out of the box.
/// Also, can't be retroactive because both are system types.
extension LocalizedStringKey: @unchecked Sendable { }

private extension LocalizedStringKey {
    static let placeholderTextKey: LocalizedStringKey = "placeholder_searchbar"
}

#if DEBUG
struct SearchFieldView_Previews: PreviewProvider {
    static var previews: some View {
        let textContent: Binding<String> = .init {
            "example"
        } set: { _ in
            //
        }
        let showKeyboard = true
        let vm: SearchFieldViewModel = .init()

        SearchFieldView(textContent, showKeyboard, vm)
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
    }
}
#endif
