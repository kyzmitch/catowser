//
//  TabsPreviewsError.swift
//  catowser
//
//  Created by Andrey Ermoshin on 11.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

enum TabsPreviewsError: LocalizedError {
    case failToLoad
    
    var errorDescription: String? {
        switch self {
        case .failToLoad:
            return "Fail to load tabs or selected tab identifier"
        }
    }
}
