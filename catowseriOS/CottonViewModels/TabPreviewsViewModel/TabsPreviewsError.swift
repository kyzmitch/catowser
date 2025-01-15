//
//  TabsPreviewsError.swift
//  catowser
//
//  Created by Andrey Ermoshin on 11.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

/// Tab previews view model errors
public enum TabsPreviewsError: LocalizedError {
    case failToLoad
    case tabsNotLoadedToClose
    case nilStateContext
    case useCaseFailure(Error)
    case notImplementedYet
    case tabsNotLoadedToInsert
    
    public var errorDescription: String? {
        switch self {
        case .failToLoad:
            return "Fail to load tabs or selected tab identifier"
        case .tabsNotLoadedToClose:
            return "Tabs not loaded to close"
        case .nilStateContext:
            return "Nil state context"
        case .useCaseFailure(let error):
            return "Use case failure: \(error)"
        case .notImplementedYet:
            return "Not implemented yet"
        case .tabsNotLoadedToInsert:
            return "Tabs not loaded to insert"
        }
    }
}
