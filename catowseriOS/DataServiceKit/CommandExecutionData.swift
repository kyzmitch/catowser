//
//  CommandExecutionData.swift
//  catowser
//
//  Created by Andrey Ermoshin on 03.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Command execution state is a common data structure
/// which combines all possible data related to specific command.
/// Each command optionally could have an input data
/// and each command for sure must have an output or an error
/// at the end of execution.
///
/// Should be used only inside GenericServiceData implementations.
/// The most close system's type is `Result`, but it doesn't allow to store the input data.
public enum CommandExecutionData<Input, Output> {
    case notStarted
    case started(input: Input?)
    case finished(output: Result<Output, Error>)
}
