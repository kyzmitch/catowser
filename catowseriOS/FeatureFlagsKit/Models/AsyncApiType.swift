//
//  AsyncApiType.swift
//  FeaturesFlagsKit
//
//  Created by Andrei Ermoshin on 10/3/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation

/// More simple analog for HttpKit.ResponseHandlingApi
public enum AsyncApiType: Int, CaseIterable, Sendable {
    case reactive
    case combine
    case asyncAwait
}
