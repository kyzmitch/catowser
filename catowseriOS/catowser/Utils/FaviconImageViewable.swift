//
//  FaviconImageViewable.swift
//  catowser
//
//  Created by Andrei Ermoshin on 7/17/23.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import UIKit
import CottonBase
import CoreBrowser
import FeatureFlagsKit
import CottonNetworking
import CottonViewModels

@MainActor protocol FaviconImageViewable: AnyObject {
    var faviconImageView: UIImageView { get }

    func reloadImageWith(
        _ site: Site,
        _ useDoH: Bool
    ) async
}

extension FaviconImageViewable {
    func reloadImageWith(_ site: Site, _ useDoH: Bool) async {
        let source: ImageSource
        let url: URL?
        do {
            url = try await site.faviconURL(useDoH, GoogleDnsClient.shared)
        } catch {
            print("Fail to resolve favicon url: \(error)")
            url = nil
        }

        switch (url, site.favicon()) {
        case (let url?, nil):
            source = .url(url)
        case (nil, let image?):
            source = .image(image)
        case (let url?, let image?):
            source = .urlWithPlaceholder(url, image)
        default:
            return
        }
        faviconImageView.updateImage(from: source)
    }
}
