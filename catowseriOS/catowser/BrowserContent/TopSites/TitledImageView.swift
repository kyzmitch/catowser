//
//  TitledImageView.swift
//  catowser
//
//  Created by Andrey Ermoshin on 24.04.2023.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonBase
import CottonNetworking
import FeatureFlagsKit

struct TitledImageView: View {
    private let site: Site
    @Binding private var isSelected: Site?

    private let cellWidth = ImageViewSizes.imageHeight
    private let titleHeight = ImageViewSizes.titleHeight
    private let titleFontSize = ImageViewSizes.titleFontSize
    @State private var url: URL?

    init(_ site: Site, _ isSelected: Binding<Site?>) {
        self.site = site
        _isSelected = isSelected
    }

    var body: some View {
        VStack {
            AsyncImage(url: url) { image in
                image.resizable(resizingMode: .stretch)
            } placeholder: {
                if let cachedImage = site.favicon() {
                    Image(uiImage: cachedImage)
                } else {
                    Color.gray
                }
            }
            .frame(width: cellWidth, height: cellWidth)
            .cornerRadius(3)
            Text(verbatim: site.title)
                .font(.system(size: titleFontSize))
                .frame(maxWidth: cellWidth, maxHeight: titleHeight)
        }
        .onTapGesture {
            isSelected = site
        }
        .task {
            let useDoH = await FeatureManager.shared.boolValue(of: .dnsOverHTTPSAvailable)
            do {
                url = try await site.faviconURL(useDoH, GoogleDnsClient.shared)
            } catch {
                print("Fail to resolve favicon URL: \(error)")
            }
        }
    }
}
