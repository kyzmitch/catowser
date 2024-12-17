//
//  TabsDataServiceProtocol.swift
//  CottonDataServices
//
//  Created by Andrei Ermoshin on 11/21/24.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

/// Tabs data service interface
public protocol TabsDataServiceProtocol: GenericDataServiceActorProtocol, TabsSubject where
Command == TabsServiceCommand,
ServiceData == TabsServiceData { }
