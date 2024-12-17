//
//  TabPreviewsContextImpl.swift
//  catowser
//
//  Created by Andrey Ermoshin on 15.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonBase
import CoreBrowser
import CottonViewModels

final class TabPreviewsContextImpl: TabPreviewsContext {
    var contentState: CoreBrowser.Tab.ContentType {
        get async {
            await DefaultTabProvider.shared.contentState
        }
    }

    @MainActor func removeWebView(for site: Site) -> Bool {
        WebViewsReuseManager.shared.removeWebView(for: site)
    }
}
