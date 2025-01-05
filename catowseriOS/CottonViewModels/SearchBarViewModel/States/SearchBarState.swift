//
//  SearchBarState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 30.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import ViewModelKit

/// Base search bar state
public class SearchBarState<C: SearchBarStateContext>: ViewModelState, @unchecked Sendable {
    public typealias Context = C
    public typealias Action = SearchBarAction
    
    /// Need to figure out if it is a search query
    public var titleString: String?
    /// Need to figure out if it is a search query
    public var searchBarContent: String?
    /// Query
    public var query: String = ""
    
    init() { }
    
    public static func createInitial() -> Self {
        // swiftlint:disable:next force_cast
        return SearchBarInViewMode() as! Self
    }
    
    /// Title of search bar
    public var title: String {
        titleString ?? ""
    }
    
    /// Text content above the search bar
    public var content: String {
        searchBarContent ?? ""
    }
    
    /// Determines if cancel button needs to be shown
    open var showCancelButton: Bool {
        false
    }
    
    @MainActor public func transitionOn(
        _ action: Action,
        with context: Context?
    ) throws -> Self {
        throw SearchBarError.invalidDummyState
    }
}
