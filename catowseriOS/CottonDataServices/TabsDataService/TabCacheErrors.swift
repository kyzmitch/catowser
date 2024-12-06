//
//  TabCacheErrors.swift
//  CoreBrowser
//
//  Created by Andrei Ermoshin on 1/4/21.
//  Copyright © 2021 Cotton (former Catowser). All rights reserved.
//

import Foundation

public enum TabResourceError: Swift.Error {
    case zombieSelf
    case storeNotInitializedYet
    case dummyError
    case insertError(Error)
    case deleteError(Error)
    case fetchAllError(Error)
    case selectedTabId(Error)
}

public enum TabStorageError: Swift.Error {
    case zombieSelf
    case dbResourceError(Error)
    case notImplemented
    case notFound
}
