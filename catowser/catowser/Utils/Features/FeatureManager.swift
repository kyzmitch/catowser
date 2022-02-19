//
//  FeatureManager.swift
//  catowser
//
//  Created by Andrei Ermoshin on 2/22/20.
//  Copyright © 2020 andreiermoshin. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif
import ReactiveSwift
import CoreBrowser

final class FeatureManager {
    private static let shared: FeatureManager = .init()
    private let sources: [FeatureSource] = [LocalFeatureSource() /*, RemoteFeatureSource()*/]
    
    private init() {}
    
    static func boolValue<F: BasicFeature>(of feature: ApplicationFeature<F>) -> Bool where F.Value == Bool {
        guard let source = source(for: feature) else {
            return F.defaultValue
        }
        return source.currentValue(of: feature)
    }
    
    static func intValue<F: BasicFeature>(of feature: ApplicationFeature<F>) -> Int where F.Value == Int {
        guard let source = source(for: feature) else {
            return F.defaultValue
        }
        return source.currentValue(of: feature)
    }
    
    static func setFeature<F: BasicFeature>(_ feature: ApplicationFeature<F>, value: F.Value?) {
        guard let source = source(for: feature) else {
            return
        }
        source.setValue(of: feature, value: value)
    }
    
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    typealias AppFeaturePublisher<F: Feature> = AnyPublisher<ApplicationFeature<F>, Never>
    
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func featureChangesPublisher<F>(for feature: ApplicationFeature<F>) -> AppFeaturePublisher<F> {
        guard let source = source(for: feature) as? ObservableFeatureSource else {
            let empty = Empty<ApplicationFeature<F>, Never>(completeImmediately: false)
            return empty.eraseToAnyPublisher()
        }
        return source.futureFeatureChanges
            .compactMap { $0 == feature ? feature : nil }
            .eraseToAnyPublisher()
    }
    
    static func rxFeatureChanges<F>(for feature: ApplicationFeature<F>) -> Signal<ApplicationFeature<F>, Never> {
        guard let source = source(for: feature) as? ObservableFeatureSource else {
            return .empty
        }
        return source.rxFutureFeatureChanges
            .filterMap { $0 == feature ? feature : nil }
    }
    
    private static func source<F>(for feature: ApplicationFeature<F>) -> FeatureSource? {
        return shared.sources.first(where: { type(of: $0) == F.source })
    }
}

// MARK: - special methods specific to features
extension FeatureManager {
    static func tabAddPositionValue() -> AddedTabPosition {
        let feature: ApplicationFeature = .tabAddPosition
        // swiftlint:disable:next force_unwrapping
        let defaultValue = AddedTabPosition(rawValue: feature.defaultValue)!
        guard let source = source(for: feature) else {
            return defaultValue
        }
        return AddedTabPosition(rawValue: source.currentValue(of: feature)) ?? defaultValue
    }
    
    static func tabDefaultContentValue() -> TabContentDefaultState {
        let feature: ApplicationFeature = .tabDefaultContent
        // swiftlint:disable:next force_unwrapping
        let defaultValue = TabContentDefaultState(rawValue: feature.defaultValue)!
        guard let source = source(for: feature) else {
            return defaultValue
        }
        return TabContentDefaultState(rawValue: source.currentValue(of: feature)) ?? defaultValue
    }
    
    static func appAsyncApiTypeValue() -> AsyncApiType {
        let feature: ApplicationFeature = .appDefaultAsyncApi
        // swiftlint:disable:next force_unwrapping
        let defaultValue = AsyncApiType(rawValue: feature.defaultValue)!
#if DEBUG
        guard let source = source(for: feature) else {
            return defaultValue
        }
        return AsyncApiType(rawValue: source.currentValue(of: feature)) ?? defaultValue
#else
        return defaultValue
#endif
    }
    
    static func webSearchAutoCompleteValue() -> WebAutoCompletionSource {
        let feature: ApplicationFeature = .webAutoCompletionSource
        // swiftlint:disable:next force_unwrapping
        let defaultValue = WebAutoCompletionSource(rawValue: feature.defaultValue)!
        guard let source = source(for: feature) else {
            return defaultValue
        }
        return WebAutoCompletionSource(rawValue: source.currentValue(of: feature)) ?? defaultValue
    }
}
