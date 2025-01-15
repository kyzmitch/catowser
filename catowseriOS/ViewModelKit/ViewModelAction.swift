//
//  ViewModelAction.swift
//  catowser
//
//  Created by Andrey Ermoshin on 23.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// View model action marker interface
///
/// It is better to be value type to be thread-safe from the scratch.
public protocol ViewModelAction: CaseIterable, Sendable { }
