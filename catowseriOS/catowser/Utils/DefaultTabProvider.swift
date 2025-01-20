//
//  DefaultTabProvider.swift
//  catowser
//
//  Created by Andrei Ermoshin on 01/02/2019.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CoreBrowser
import FeatureFlagsKit
import CottonBase
import CottonDataServices

/// Provides default tab related constants, no need to be global actor, because read-only
@globalActor
final class DefaultTabProvider {
    static let shared = StateHolder()
    
    actor StateHolder: TabsStatesInterface {
        @MainActor var selected: Bool {
            UIDevice.current.userInterfaceIdiom == .pad
        }

        let blockPopups: Bool = false

        func topSites(_ isJsEnabled: Bool) -> [Site] {
            let array: [Site?]
            let settings: Site.Settings = .init(
                isPrivate: false,
                blockPopups: blockPopups,
                isJSEnabled: isJsEnabled,
                canLoadPlugins: true
            )
            let opennet = Site("https://opennet.ru", "OpenNet", settings)
            let yahooFinance = Site("https://finance.yahoo.com", "Yahoo Finance", settings)
            let github = Site("https://github.com", "GitHub", settings)
            #if DEBUG
            let mailToLink = Site("https://www.k8oms.net/links/mailto-link", "k8oms", settings)
            let mapsV1 = Site("https://www.apple.com/maps/", "apple maps", settings)
            array = [opennet, yahooFinance, github, mailToLink, mapsV1]
            #else
            array = [opennet, yahooFinance, github]
            #endif
            return array.compactMap {$0}
        }
        
        var addPosition: AddedTabPosition {
            get async {
                await FeatureManager.shared.tabAddPositionValue()
            }
        }

        var contentState: CoreBrowser.Tab.ContentType {
            get async {
                await FeatureManager.shared.tabDefaultContentValue()
            }
        }

        nonisolated var addSpeed: TabAddSpeed { .after(.milliseconds(300)) }

        nonisolated var defaultSelectedTabId: UUID { .notPossibleId }
    }
}

private extension UUID {
    static let notPossibleId: UUID = .init(uuid: (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1))
}
