//
//  BaseListViewModelImpl.swift
//  ViewModelKit
//
//  Created by Andrey Ermoshin on 19.02.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CoreBrowser
import ViewModelKit

/// Base list view model implementation
public struct BaseListViewModel<SourceType: FullEnumTypeConstraints>: BaseListViewModelInterface where SourceType.RawValue == Int {
    public typealias EnumDataSourceType = SourceType

    public let dataSource: EnumDataSourceType.AllCases = EnumDataSourceType.allCases

    public let viewTitle: String

    public let onPop: PopClosure

    /// Need to improve/re-desing Feature system to initialize it here based on a generic type instead of init usage
    public let selected: EnumDataSourceType

    public init(
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
