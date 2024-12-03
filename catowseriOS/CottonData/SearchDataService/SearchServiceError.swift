//
//  SearchServiceError.swift
//  catowser
//
//  Created by Andrey Ermoshin on 03.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

public enum SearchServiceError: DataServiceKitError {
    case zombyInstance
    case sameSearchQueryAlreadyInProgress
    case strategyError(Error)

    public init(zombyInstance: Bool) {
        self = .zombyInstance
    }
}
