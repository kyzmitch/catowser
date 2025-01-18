//
//  TopSitesViewV2.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/24/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonBase
import CoreBrowser
import CottonViewModels
import TcaFrameworkWrapper

@available(iOS 17.0, *)
struct TopSitesViewV2: View {
    @State private var selected: Site?
    @Bindable var store: StoreOf<TopSitesReducer>

    /// Number of items which will be displayed in a row
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        Group {
            switch store.currentState {
            case .loading:
                ProgressView()
            case .loaded(let topSites):
                ScrollView {
                    LazyVGrid(columns: columns, spacing: ImageViewSizes.spacing) {
                        ForEach(topSites) { TitledImageView($0, $selected) }
                    }
                }
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .onChange(of: selected) { newValue in
                    guard let newValue else {
                        return
                    }
                    store.send(.selectSite(.site(newValue)))
                }
            }
        }
        .onAppear {
            store.send(.fetchSites)
        }
    }
}
