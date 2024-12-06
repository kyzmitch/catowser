//
//  TabsListError.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 25.07.2023.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import Foundation

public enum TabsListError: LocalizedError {
    case notInitializedYet
    case selectedNotFound
    case wrongTabContent
    case wrongTabIndexToReplace
    case tabContentAlreadySet
    case failToUpdateTabContent
}
