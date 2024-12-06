//
//  LocalSettings.swift
//  FeaturesFlagsKit
//
//  Created by Andrei Ermoshin on 2/22/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import Foundation

@globalActor
final class LocalSettings {
    static let shared = StateHolder()

    actor StateHolder {
        private let userDefaults: UserDefaults

        init(
            userDefaults: UserDefaults = .init()
        ) {
            self.userDefaults = userDefaults
        }

        func getString(for key: String) -> String? {
            return userDefaults.string(forKey: key)
        }

        func getInt(for key: String) -> Int? {
            guard userDefaults.object(forKey: key) != nil else {
                return nil
            }
            return userDefaults.integer(forKey: key)
        }

        func getBool(for key: String) -> Bool? {
            guard userDefaults.object(forKey: key) != nil else {
                return nil
            }
            return userDefaults.bool(forKey: key)
        }

        func setBool(for key: String, value: Bool) {
            userDefaults.set(value, forKey: key)
        }

        func setInt(for key: String, value: Int) {
            userDefaults.set(value, forKey: key)
        }
    }
}
