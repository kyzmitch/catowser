//
//  TabsListError.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 25.07.2023.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import Foundation
import DataServiceKit

/// Tabs data service errors
public enum TabsListError: DataServiceKitError {
    public init(zombyInstance: Bool) {
        self = .zombyInstance
    }
    
    case zombyInstance
    case notInitializedYet
    case selectedNotFound
    case wrongTabContent
    case wrongTabIndexToReplace
    case noAnyTabs
    case repositoryFailure(NSError)
    case failToRemoveTab
    case failToAddDefaultTab
    case closingNonExistingTab
    case failToFindNewSelectedTab
    case onlyDefaultTabPresent
    
    public var errorDescription: String? {
        switch self {
        case .zombyInstance:
            "Tabs data service is nil"
        case .notInitializedYet:
            "Tabs data service is not initialized yet"
        case .selectedNotFound:
            "Selected tab is not found"
        case .wrongTabContent:
            "Unexpected tab content"
        case .wrongTabIndexToReplace:
            "Unexpected tab index to replace (out of bounds)"
        case .noAnyTabs:
            "No any tabs found (expect at least 1)"
        case .repositoryFailure(let nsError):
            "Tabs repository failure (\(nsError.localizedDescription))"
        case .failToRemoveTab:
            "Fail to remove a tab"
        case .failToAddDefaultTab:
            "Fail to add default single tab"
        case .closingNonExistingTab:
            "Attempt to close not existing tab"
        case .failToFindNewSelectedTab:
            "Fail to auto-select new tab"
        case .onlyDefaultTabPresent:
            "Tried to update custom tab, but only default present"
        }
    }
}
