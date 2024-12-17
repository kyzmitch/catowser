//
//  NavigationActionable.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import WebKit

/// Interface for system's type `WKNavigationAction` from WebKit framework to be able to mock it.
///
/// Can be sendable because both fields are.
/// Also,`WKNavigationAction` which has these fields and confirms to this protocol,
/// it is marked as a main actor, so that, this protocol should be marked as main actor as well.
@MainActor public protocol NavigationActionable: AnyObject, Sendable {
    var navigationType: WKNavigationType { get }
    var request: URLRequest { get }
}
