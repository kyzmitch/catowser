//
//  TabAddPositionsModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 5/31/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CoreBrowser
import CottonViewModels
import CottonDataServices

typealias TabAddPositionsModel = BaseListViewModel<AddedTabPosition>

extension BaseListViewModel where EnumDataSourceType == AddedTabPosition {
    init(
        _ selected: EnumDataSourceType?,
        _ completion: @escaping PopClosure
    ) {
        let localizedTitle = NSLocalizedString("ttl_tab_positions", comment: "")
        self.init(localizedTitle, completion, selected)
    }
}

/// Declare string representation for CoreBrowser enum
/// in host app to use localized strings.
extension AddedTabPosition: @retroactive CustomStringConvertible {
    public var description: String {
        let key: String

        switch self {
        case .listEnd:
            key = "txt_tab_add_list_end"
        case .afterSelected:
            key = "txt_tab_add_after_selected"
        @unknown default:
            fatalError("Not handled tab add position type")
        }
        return NSLocalizedString(key, comment: "")
    }
}

extension AddedTabPosition: @retroactive Identifiable {
    public var id: RawValue {
        return self.rawValue
    }

    public typealias ID = RawValue
}
