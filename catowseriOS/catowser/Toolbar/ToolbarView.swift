//
//  ToolbarView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 12/11/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import UIKit
import SwiftUI
import CottonViewModels

/// Only UIKit wrapper which needs less amout of parameters than full SwiftUI view
struct ToolbarView: View {
    @EnvironmentObject var model: BrowserToolbarViewModel

    var body: some View {
        ToolbarLegacyView(model.state.webViewInterface)
            .frame(height: CGFloat.toolbarViewHeight)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                DummyView()
            }
    }
}

private struct DummyView: View {
    var body: some View {
        EmptyView()
            .frame(height: 0)
            .background(Color.phoneToolbarColor)
    }
}

#if DEBUG
struct ToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
    }
}
#endif
