//
//  TabsStates.swift
//  CoreBrowser
//
//  Created by Andrei Ermoshin on 5/30/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import AutoMockable

public protocol TabsStates: AutoMockable, Sendable {
    var addPosition: AddedTabPosition { get async }
    var contentState: Tab.ContentType { get async }
    var addSpeed: TabAddSpeed { get }
    var defaultSelectedTabId: Tab.ID { get }
}
