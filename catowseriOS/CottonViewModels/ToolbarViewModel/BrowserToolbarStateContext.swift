//
//  BrowserToolbarStateContext.swift
//  catowser
//
//  Created by Andrey Ermoshin on 23.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import ViewModelKit

/// Browser toolbar state context interface
public protocol BrowserToolbarStateContext: StateContext {
    var siteNavigationDelegate: SiteNavigationChangable? { get }
}

/// Browser toolbar state context
public final class BrowserToolbarStateContextProxy: BrowserToolbarStateContext {
    private let subject: any BrowserToolbarStateContext
    
    init(subject: any BrowserToolbarStateContext) {
        self.subject = subject
    }
    
    public var siteNavigationDelegate: SiteNavigationChangable? {
        nil
    }
}

/**
 private var vcFactory: ViewControllerFactory {
     UIServiceRegistry.shared().vcFactory
 }
 
 if UIDevice.current.userInterfaceIdiom == .phone {
     return vcFactory.createdToolbaViewController as? SiteNavigationChangable
 } else {
     return vcFactory.createdDeviceSpecificSearchBarVC as? SiteNavigationChangable
 }
 */
