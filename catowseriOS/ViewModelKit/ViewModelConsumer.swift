//
//  ViewModelConsumer.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import Combine

/// An interface of MVVM view model consumer (usually view controller).
/// 
/// It requires to have only one view model with `viewModel` field name.
/// So that, if controller or view has more that one view model, then need
/// to combine them into a single view model wrapper if needed.
///
/// TBD: For now this is for UIKit, need to add an API/interface for SwiftUI as well.
@MainActor public protocol ViewModelConsumer {
    /// View model type
    associatedtype ViewModel: ViewModelInterface
    /// State
    associatedtype State: ViewModelState where State == ViewModel.State
    
    /// An instance of view model stored for view controller (or any view)
    ///
    /// TBD: Could inject it automatically from the view models factory later.
    var viewModel: ViewModel { get }
    /// Handles the state change
    func onStateChange(_ nextState: State)
    /// Subscribe for view model's state change
    func startStateObserving() -> AnyCancellable
}

extension ViewModelConsumer where Self: AnyObject {
    public func startStateObserving() -> AnyCancellable {
        // Render initial state
        onStateChange(viewModel.state)
        // Observe all next states
        return viewModel.statePublisher.sink { failure in
            print("Fail to start state observing: \(failure)")
        } receiveValue: { nextState in
            self.onStateChange(nextState)
        }
    }
}
