//
//  TabDefaultContentModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/1/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import CottonViewModels

typealias TabDefaultContentModel = BaseListViewModel<CoreBrowser.Tab.ContentType>

extension BaseListViewModel where EnumDataSourceType == CoreBrowser.Tab.ContentType {
    init(
        _ selected: EnumDataSourceType?,
        _ completion: @escaping PopClosure
    ) {
        let title = NSLocalizedString("ttl_tab_default_content", comment: "")
        self.init(title, completion, selected)
    }
}
