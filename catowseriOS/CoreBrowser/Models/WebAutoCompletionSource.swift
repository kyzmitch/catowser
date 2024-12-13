//
//  WebAutoCompletionSource.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 03.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Web search completion source
public enum WebAutoCompletionSource: Int, CaseIterable, Sendable {
    case google
    case duckduckgo
    
    /// To find file, can't use Custom string convertible
    /// because it is already being used for human readable values with spaces
    public var stringKey: String {
        switch self {
        case .google:
            "google"
        case .duckduckgo:
            "duckduckgo"
        }
    }
}
