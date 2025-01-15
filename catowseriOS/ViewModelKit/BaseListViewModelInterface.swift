//
//  BaseListViewModel.swift
//  ViewModelKit
//
//  Created by Andrey Ermoshin on 19.02.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

/// Base list view model
///
/// A view model type which can be used for the menu items
@MainActor public protocol BaseListViewModelInterface {
    /// The type of the data, always an enumeration
    associatedtype EnumDataSourceType: CaseIterable
    /// The type of the callback which returns the selected value/case
    typealias PopClosure = (EnumDataSourceType) -> Void

    /// All possible cases of data
    var dataSource: EnumDataSourceType.AllCases { get }
    /// Title string (name of the data)
    var viewTitle: String { get }
    /// Mandatory callback for selected case/value
    var onPop: PopClosure { get }
    /// Selected value/case
    var selected: EnumDataSourceType { get }
}
