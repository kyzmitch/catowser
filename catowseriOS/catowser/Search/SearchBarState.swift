//
//  SearchBarState.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/23/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CoreBrowser
import CottonBase

/// The sate of search bar
enum SearchBarState: Equatable {
    /// Initial state for a new blank tab.
    case blankViewMode
    /// When keyboard and `cancel` button are visible.
    /// Need to carry title & content from view mode to be able to revert any editing.
    case inSearchMode(_ initialTitle: String, _ initialSearchBarContent: String)
    /// When keyboard and all buttons are not displayed.
    case viewMode(_ title: String, _ searchBarContent: String, _ animated: Bool)

    var title: String {
        switch self {
        case .blankViewMode:
            return ""
        case .inSearchMode(let initialTitle, _):
            return initialTitle
        case .viewMode(let initialTitle, _, _):
            return initialTitle
        }
    }

    var content: String {
        switch self {
        case .blankViewMode:
            return ""
        case .inSearchMode(_, let initialContent):
            return initialContent
        case .viewMode(_, let initialContent, _):
            return initialContent
        }
    }

    var showCancelButton: Bool {
        switch self {
        case .blankViewMode, .viewMode:
            return false
        case .inSearchMode:
            return true
        }
    }
}
