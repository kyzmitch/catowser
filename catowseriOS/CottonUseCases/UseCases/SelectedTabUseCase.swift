//
//  SelectedTabUseCase.swift
//  CoreBrowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import AutoMockable
import Foundation

/// Selected tabs use case.
/// Use cases do not hold any mutable state, so that, any of them can be sendable.
public protocol SelectedTabUseCase: BaseUseCase, AutoMockable, Sendable {
    func setSelectedPreview(_ image: Data?) async throws(AppError)
}
