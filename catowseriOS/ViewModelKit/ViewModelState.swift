//
//  ViewModelState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// View model state marker interface
///
/// Can be value type (struct or enum) to be thread-safe out of the box.
/// But it is not required, you can use classes and inheritance to
/// implement canonical state design pattern as well.
public protocol ViewModelState: Sendable, Equatable {
    /// Action type
    associatedtype Action: ViewModelAction
    /// Context of the state to be able to get any additional data
    /// required for action handling or state conversion.
    associatedtype Context: StateContext
    /// Base state type, needed for class/ref states to be able to use base class
    /// in initial instance and transition functions.
    associatedtype BaseState: ViewModelState where BaseState.Action == Action, BaseState.Context == Context

    /// Create an initial state which is needed for View Model init
    ///
    /// e.g. it could be loading state at the beginning
    static func createInitial() -> BaseState

    /// Converts current state to another valid state based on input action.
    /// This function should be async, because action handling usually is not serial.
    ///
    /// - Parameter action: An action which tells how to convert the state
    /// - Parameter context: An optional state context if it is needed for state conversion/handling
    /// - Returns same or modified state value, depending if action was valid or not for the current state
    @MainActor func transitionOn(
        _ action: Action,
        with context: Context?
    ) async throws -> BaseState
    
    /// Converts current state to another valid state or Result failure.
    /// This function has async closure for completion, because
    /// action handling usually depends on async operations.
    ///
    /// - Parameter action: An action which tells how to convert the state
    /// - Parameter context: An optional state context if it is needed for state conversion/handling
    /// - Parameter onComplete: Completion closure with new state or failure
    @MainActor func transitionOn(
        _ action: Action,
        with context: Context?,
        onComplete: @escaping (Result<BaseState, Error>) -> Void
    )
}

extension ViewModelState {
    @MainActor public func transitionOn(
        _ action: Action,
        with context: Context?,
        onComplete: @escaping (Result<BaseState, Error>) -> Void
    ) {
        Task {
            do {
                let nextState = try await transitionOn(action, with: context)
                onComplete(.success(nextState))
            } catch {
                onComplete(.failure(error))
            }
        }
    }
}
