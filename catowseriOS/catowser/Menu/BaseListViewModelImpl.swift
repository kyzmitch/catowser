//
//  BaseListViewModelImpl.swift
//  catowser
//
//  Created by Andrey Ermoshin on 19.02.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import FeaturesFlagsKit

struct BaseListViewModelImpl<SourceType: FullEnumTypeConstraints>: BaseListViewModel where SourceType.RawValue == Int {
    typealias EnumDataSourceType = SourceType

    let dataSource: EnumDataSourceType.AllCases = EnumDataSourceType.allCases

    let viewTitle: String

    let onPop: PopClosure

    /// Need to improve/re-desing Feature system to initialize it here based on a generic type instead of init usage
    let selected: EnumDataSourceType

    init(
        _ viewTitle: String,
        _ onPop: @escaping PopClosure,
        _ selected: EnumDataSourceType?
    ) {
        // Using random/first enum value just because it seems
        // it is not possible to pass just a type name
        // swiftlint:disable:next force_unwrapping
        let enumCase = EnumDataSourceType.allCases.first!
        self.selected = selected ?? enumCase.defaultValue
        self.viewTitle = viewTitle
        self.onPop = onPop
    }
}
