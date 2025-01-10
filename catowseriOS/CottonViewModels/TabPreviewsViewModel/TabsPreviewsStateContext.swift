//
//  TabsPreviewsStateContext.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/10/25.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import ViewModelKit

public protocol TabsPreviewsStateContext: StateContext { }

public final class TabsPreviewsStateContextProxy: TabsPreviewsStateContext {
    private let subject: any TabsPreviewsStateContext
    
    init(subject: any TabsPreviewsStateContext) {
        self.subject = subject
    }
}
