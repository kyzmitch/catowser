//
//  ReducersFactory.swift
//  catowser
//
//  Created by Andrey Ermoshin on 18.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import FeatureFlagsKit
import CottonUseCases
import CottonViewModels

@MainActor final class ReducersFactory {
    static let shared: ReducersFactory = .init()
    
    private let useCaseRegistry: UseCaseRegistry.StateHolder
    private let featureManager: FeatureManager.StateHolder
    private let defaultTabProvider: DefaultTabProvider.StateHolder
    
    private init(
        _ useCaseRegistry: UseCaseRegistry.StateHolder = UseCaseRegistry.shared,
        _ featureManager: FeatureManager.StateHolder = FeatureManager.shared,
        _ defaultTabProvider: DefaultTabProvider.StateHolder = DefaultTabProvider.shared
    ) {
        self.useCaseRegistry = useCaseRegistry
        self.featureManager = featureManager
        self.defaultTabProvider = defaultTabProvider
    }
    
    func topSitesReducer() async -> TopSitesReducer {
        let isJsEnabled = await featureManager.boolValue(of: .javaScriptEnabled)
        async let writeUseCase = useCaseRegistry.findUseCase(WriteTabsUseCase.self)
        let context = TopSitesAppContextImpl(isJsEnabled, DefaultTabProvider.shared)
        return await TopSitesReducer(context, writeUseCase)
    }
}
