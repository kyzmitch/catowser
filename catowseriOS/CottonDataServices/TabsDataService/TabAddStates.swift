//
//  TabAddStates.swift
//  CoreBrowser
//
//  Created by Andrei Ermoshin on 5/30/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation

/// Describes how new tab is added to the list.
/// Uses `Int` as raw value to be able to store it in settings.
public enum AddedTabPosition: Int, CaseIterable, Sendable {
    case listEnd = 0
    case afterSelected = 1
}

public enum TabAddSpeed {
    case immediately
    case after(DispatchTimeInterval)
}

extension DispatchTimeInterval {
    @available(iOS 16.0, *)
    public var dispatchValue: Duration {
        switch self {
        case .seconds(let int):
            return .seconds(int)
        case .milliseconds(let int):
            return .milliseconds(int)
        case .microseconds(let int):
            return .microseconds(int)
        case .nanoseconds(let int):
            return .nanoseconds(int)
        case .never:
            return .zero
        @unknown default:
            // Returning default value instead of fatalError
            return .zero
        }
    }

    public var inNanoseconds: UInt64 {
        switch self {
        case .seconds(let int):
            return 1000000000 * UInt64(int)
        case .milliseconds(let int):
            return 1000000 * UInt64(int)
        case .microseconds(let int):
            return 1000 * UInt64(int)
        case .nanoseconds(let int):
            return UInt64(int)
        case .never:
            return 0
        @unknown default:
            // Returning default value instead of fatalError
            return 0
        }
    }
}
