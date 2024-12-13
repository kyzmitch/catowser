//
//  DispatchQueueInterface.swift
//  catowser
//
//  Created by Andrey Ermoshin on 25.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Dispatch

public protocol DispatchQueueInterface: Sendable {
    @preconcurrency func performAsync(
        execute work: @escaping @Sendable @convention(block) () -> Void
    )
}

extension DispatchQueue: DispatchQueueInterface {
    public func performAsync(
        execute work: @escaping @Sendable @convention(block) () -> Void
    ) {
        self.async(execute: work)
    }
}
