//
//  TopSitesView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 12/17/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CottonViewModels
import ComposableArchitecture

struct TopSitesView: View {
    @EnvironmentObject private var vm: TopSitesViewModel
    /// Selected swiftUI mode which is set at app start
    private let mode: SwiftUIMode

    init(_ mode: SwiftUIMode) {
        self.mode = mode
    }

    var body: some View {
        switch mode {
        case .compatible:
            TopSitesLegacyView()
        case .full:
            TopSitesViewV2()
        }
    }
}
