//
//  SearchServiceData.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

public struct SearchServiceData: GenericServiceData {
    var resolvedUrl: URL?
    var autocompleteSuggestions: [String]?
    
    public init() { }
}
