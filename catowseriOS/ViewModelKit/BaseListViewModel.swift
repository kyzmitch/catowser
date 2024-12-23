//
//  BaseListViewModel.swift
//  ViewModelKit
//
//  Created by Andrey Ermoshin on 19.02.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation

@MainActor public protocol BaseListViewModel {
    associatedtype EnumDataSourceType: CaseIterable

    typealias PopClosure = (EnumDataSourceType) -> Void

    var dataSource: EnumDataSourceType.AllCases { get }
    var viewTitle: String { get }
    var onPop: PopClosure { get }
    var selected: EnumDataSourceType { get }
}
