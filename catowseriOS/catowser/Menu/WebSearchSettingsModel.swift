//
//  WebSearchSettingsModel.swift
//  BrowserNetworking
//
//  Created by Andrey Ermoshin on 19.02.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonData
import CoreBrowser
import Foundation

typealias WebSearchSettingsModel = BaseListViewModelImpl<WebAutoCompletionSource>

extension BaseListViewModelImpl where EnumDataSourceType == WebAutoCompletionSource {
    init(
        _ selected: EnumDataSourceType?,
        _ completion: @escaping PopClosure
    ) {
        self.init(NSLocalizedString("ttl_search_menu", comment: ""),
                  completion,
                  selected)
    }
}

extension WebAutoCompletionSource: CustomStringConvertible {
    public var description: String {
        let key: String

        // No need to localize the names
        switch self {
        case .duckduckgo:
            key = "Duck Duck Go"
        case .google:
            key = "Google"
        @unknown default:
            fatalError("Not handled search provider type")
        }
        return key
    }
}

extension WebAutoCompletionSource: Identifiable {
    public var id: RawValue {
        return self.rawValue
    }

    public typealias ID = RawValue
}
