//
//  UIServiceRegistry.swift
//  catowser
//
//  Created by Andrey Ermoshin on 19.09.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import UIKit

/// A service registry used only as a main actor for UI
/// to be able to use it in SwiftUI or UIKit views for observing
/// because even if it is a global state it makes it complicated
/// if it is a global actor.
@MainActor final class UIServiceRegistry {
    /// Shared instance
    static func shared() -> UIServiceRegistry {
        if let holder = internalInstance {
            return holder
        }

        let created = UIServiceRegistry(DefaultTabProvider.shared)
        internalInstance = created
        return created
    }
    
    /// Internal instance for the singletone
    static private var internalInstance: UIServiceRegistry?
    
    /// Default positioning settings
    private let positioning: TabsStates
    /// A workaround to be able to use available marker.
    ///
    /// Should be main actor data beacuse observed almost
    /// everytime in some view controller.
    private var _tabsSubject: Any? = nil
    /// Yet another way for observing, the most modern way.
    ///
    /// Should be main actor instead of data service own actor,
    /// because it will be observed almost everytime in some view controller.
    @available(iOS 17.0, *)
    public var tabsSubject: TabsDataSubject {
        if _tabsSubject == nil {
            _tabsSubject = TabsDataSubject(positioning)
        }
        return _tabsSubject as! TabsDataSubject
    }
    
    /// web views reuse manager
    let reuseManager: WebViewsReuseManager
    /// view controller factory
    let vcFactory: ViewControllerFactory
    
    private init(
        _ positioning: TabsStates
    ) {
        self.positioning = positioning
        // Could read global state to inject current UIFrameworkType value right away,
        // and it will make init block this init, probably not good idea
        if UIDevice.current.userInterfaceIdiom == .pad {
            vcFactory = TabletViewControllerFactory()
        } else {
            vcFactory = PhoneViewControllerFactory()
        }
        reuseManager = .init(vcFactory)
    }
}

extension WebViewsReuseManager {
    static var shared: WebViewsReuseManager {
        return UIServiceRegistry.shared().reuseManager
    }
}
