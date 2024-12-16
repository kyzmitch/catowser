//
//  SuggestionType.swift
//  CottonViewModels
//
//  Created by Andrey Ermoshin on 16.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

public enum SuggestionType: Equatable {
    case suggestion(String)
    case knownDomain(String)
    case looksLikeURL(String)
}
