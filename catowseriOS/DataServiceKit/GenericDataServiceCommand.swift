//
//  GenericDataServiceCommand.swift
//  catowser
//
//  Created by Andrey Ermoshin on 25.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// An interface to implement Command design pattern for a data service
/// this type should allow to provide a common interface for any data service
/// by using a single function in the data service API which has a command
/// as an input parameter
public protocol GenericDataServiceCommand: CaseIterable, Hashable { }
