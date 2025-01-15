//
//  BrowserToolbarViewContextImpl.swift
//  catowser
//
//  Created by Andrey Ermoshin on 23.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonViewModels
import UIKit

final class BrowserToolbarViewContextImpl: BrowserToolbarViewContext {
    var siteNavigationDelegate: SiteNavigationChangable? {
        let controller: UIViewController?
        if UIDevice.current.userInterfaceIdiom == .phone {
            controller = vcFactory.createdToolbaViewController
        } else {
            controller = vcFactory.createdDeviceSpecificSearchBarVC
        }
        return controller as? SiteNavigationChangable
    }
    
    private var vcFactory: ViewControllerFactory {
        UIServiceRegistry.shared().vcFactory
    }
}
