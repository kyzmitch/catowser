//
//  SearchBarViewV2.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/3/23.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CottonViewModels

/**
 A search bar fully implemented in SwiftUI.

 - after moving focus to TextField (tap on it) if query is not empty, then need to select all text
 which would allow to easely clear/remove currently entered query string. The same behaviour has Safari for iOS.
 - need to use the same logic for overlay view to show/hide it from SearchBarLegacyView
 createShowedLabelConstraint and hiddenLabelConstraint
 */
struct SearchBarViewV2: View {
    @Environment(\.horizontalSizeClass) var hSizeClass

    @Binding private var query: String
    /// To be able to propagate gestures/taps from this view to the upper/super view
    @Binding private var action: SearchBarAction
    @State private var showClearButton: Bool = false
    @State private var showCancelButton: Bool = false
    @State private var siteName: String = ""
    @State private var showOverlay: Bool = false
    @State private var showKeyboard: Bool = false

    @StateObject private var cancelBtnVM: ClearCancelButtonViewModel = .init()
    @StateObject private var textFieldVM: SearchFieldViewModel = .init()
    @StateObject private var overlayVM: TappableTextOverlayViewModel = .init()
    @ObservedObject var searchBarVM: SearchBarViewModel

    private let overlayHidden: CGFloat = -UIScreen.main.bounds.width

    init(
        _ query: Binding<String>,
        _ action: Binding<SearchBarAction>,
        _ searchBarVM: SearchBarViewModel
    ) {
        _query = query
        _action = action
        self.searchBarVM = searchBarVM
    }

    var body: some View {
        ZStack {
            HStack {
                SearchFieldView($query, showKeyboard, textFieldVM)
                if showCancelButton {
                    ClearCancelPairButton(showClearButton, cancelBtnVM)
                }
            }.customHStackStyle()
            .opacity(showOverlay ? 0 : 1)
            .animation(.easeInOut(duration: SearchBarConstants.animationDuration), value: showOverlay)
            TappableTextOverlayView(siteName, overlayVM)
                .opacity(showOverlay ? 1 : 0)
                .offset(x: showOverlay ? 0 : (hSizeClass == .compact ? overlayHidden : -overlayHidden), y: 0)
                .animation(.easeInOut(duration: SearchBarConstants.animationDuration), value: showOverlay)
        }
        .onReceive(searchBarVM.$state) { value in
            switch value {
            case is SearchBarInViewMode:
                guard let title = value.titleString, let content = value.searchBarContent else {
                    showKeyboard = false
                    query = ""
                    siteName = ""
                    showOverlay = false
                    return
                }
                showKeyboard = false
                query = content
                siteName = title
                showOverlay = true
            case is SearchBarInSearchMode:
                showOverlay = false
                showKeyboard = true
            default:
                break
            }
        }
        .onChange(of: query) { showClearButton = !$0.isEmpty }
        .onReceive(cancelBtnVM.$clearTapped.dropFirst()) { query = "" }
        .onReceive(cancelBtnVM.$cancelTapped.dropFirst()) { action = .cancelSearch }
        .onReceive(textFieldVM.$submitTapped.dropFirst()) { action = .cancelSearch }
        .onReceive(textFieldVM.$isFocused.dropFirst()) { newValue in
            if newValue {
                action = .startSearch(nil)
            }
        }
        .onReceive(overlayVM.$tapped.dropFirst()) { action = .startSearch(nil) }
    }
}

private struct CustomHStackStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal)
            .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
            .foregroundColor(.secondary)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10.0)
    }
}

extension View {
    func customHStackStyle() -> some View {
        modifier(CustomHStackStyle())
    }
}

#if DEBUG
struct SearchBarViewV2_Previews: PreviewProvider {
    static var previews: some View {
        let action: Binding<SearchBarAction> = .init {
            .updateView("example.com", "https://example.com/")
        } set: { _ in
            //
        }
        let query: Binding<String> = .init {
            ""
        } set: { _ in
            //
        }
        let viewModel = SearchBarViewModel()

        // For some reason it jumps after selection
        SearchBarViewV2(query, action, viewModel)
            .frame(maxWidth: 400)
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
    }
}
#endif
