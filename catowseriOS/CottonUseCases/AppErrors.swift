//
//  AppErrors.swift
//  catowser
//
//  Created by Andrei Ermoshin on 7/26/21.
//  Copyright © 2021 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonData
import CottonDataServices

/// Errors used on use case level
public enum AppError: LocalizedError {
    case zombieSelf
    case searchDataServiceError(SearchServiceError)
    case erasedSearchDataServiceError(Error)
}
