//
//  ViewModelConsumer.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

/// An interface of MVVM view model consumer (usually view controller).
/// 
/// It requires to have only one view model with that field name.
@MainActor public protocol ViewModelConsumer {
    /// View model type
    associatedtype ViewModel: ViewModelInterface
    /// State
    associatedtype State: ViewModelState where State == ViewModel.State
    
    /// An instance of view model stored for view controller (or any view)
    var viewModel: ViewModel { get }
    /// Handles the state change
    func onStateChange(_ nextState: State)
}
