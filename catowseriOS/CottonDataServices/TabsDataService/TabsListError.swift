//
//  TabsListError.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 25.07.2023.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import Foundation
import DataServiceKit

public enum TabsListError: DataServiceKitError {
    public init(zombyInstance: Bool) {
        self = .zombyInstance
    }
    
    case zombyInstance
    case notInitializedYet
    case selectedNotFound
    case wrongTabContent
    case wrongTabIndexToReplace
    case tabContentAlreadySet
    case noAnyTabs
    case repositoryFailure(NSError)
    case failToRemoveTab
    case failToAddDefaultTab
    case closingNonExistingTab
    case failToFindNewSelectedTab
}
