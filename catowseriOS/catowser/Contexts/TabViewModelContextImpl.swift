//
//  TabViewModelContextImpl.swift
//  catowser
//
//  Created by Andrey Ermoshin on 15.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonBase
import CottonDataServices
import CottonViewModels
import FeatureFlagsKit

final class TabViewModelContextImpl: TabViewModelContext {
    var observingApiTypeValue: ObservingApiType {
        get async {
            await FeatureManager.shared.observingApiTypeValue()
        }
    }
    
    func removeController(for site: Site) -> Bool {
        WebViewsReuseManager.shared.removeController(for: site)
    }
    
    func isDohEnabled() async -> Bool {
        await FeatureManager.shared.boolValue(of: .dnsOverHTTPSAvailable)
    }
    
    func faviconURL(
        _ site: Site,
        _ resolve: Bool
    ) async throws -> URL {
        try await site.faviconURL(resolve)
    }
    
    @available(iOS 17.0, *)
    var tabsSubject: TabsDataSubject {
        get async {
            await UIServiceRegistry.shared().tabsSubject
        }
    }
}
