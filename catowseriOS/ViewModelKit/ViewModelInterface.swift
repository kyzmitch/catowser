//
//  ViewModelInterface.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Combine

/// Base view model interface.
///
/// Always has to be a reference type (AnyObject)
@MainActor public protocol ViewModelInterface: AnyObject, Sendable {
    /// Type of the associated state
    associatedtype State: ViewModelState where State == State.BaseState
    /// Type of an action
    associatedtype Action: ViewModelAction where Action == State.Action
    /// State context to not expose the view model type.
    associatedtype Context: StateContext where State.Context == Context
    /// Completion callback type
    typealias CompletionCallback = (Result<Void, Error>) -> Void

    /// UI state of view model
    var state: State { get set }
    /// Combine publisher for the UI state
    var statePublisher: Published<State>.Publisher { get }
    /// State context which could help to convert the state on incoming action.
    /// Usually it should be a wrapper around view model implementation.
    var context: Context? { get }
    /// Apply an action to the view model state to get a new valid state
    /// - Parameter action: an action to apply to the state
    /// - Throws an error if incoming action is not valid for a current state or due to other errors
    func sendAction(
        _ action: Action
    ) async throws
    /// Apply an action to the view model state using closure API.
    ///
    /// - Parameter action: an action to apply to the state
    /// - Parameter onComplete: Completion closure.
    func sendAction(
        _ action: Action,
        onComplete: CompletionCallback?
    )
}

extension ViewModelInterface {
    public func sendAction(
        _ action: Action
    ) async throws {
        state = try await state.transitionOn(action, with: context)
    }
    
    public func sendAction(
        _ action: Action,
        onComplete: CompletionCallback?
    ) {
        state.transitionOn(action, with: context) { [weak self] result in
            switch result {
            case .success(let nextState):
                self?.state = nextState
                let void: Void = ()
                onComplete?(.success(void))
            case .failure(let failure):
                onComplete?(.failure(failure))
            }
        }
    }
}
