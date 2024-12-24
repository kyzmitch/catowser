//
//  StateContext.swift
//  
//
//  Created by Andrey Ermoshin on 23.12.2024.
//

/// View model state context type,
///
/// It is optional for the state, but could be usefull to
/// determine how to convert from one state value to another.
/// Usually state context is a view model itself, but
/// view model implementation is better to be hidden behind this interface.
@MainActor public protocol StateContext: AnyObject, Sendable { }
