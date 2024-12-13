//
//  WebViewContext.swift
//  CottonViewModels
//
//  Created by Andrei Ermoshin on 8/4/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonPlugins
import CottonBase
import FeatureFlagsKit
import CoreBrowser

/**
 For more info about usage any keyword see:
 https://swiftrocks.com/whats-any-understanding-type-erasure-in-swift
 */

/// Web view context should carry some data or dependencies which can't be stored as a state and always are present.
/// protocol with async functions which do not belong to specific actor.
///
/// Can be sendable because doesn't store anything mutable.
public protocol WebViewContext: Sendable {
    /// Plugins are optional because there is possibility that js files are not present or plugins delegates are not set
    var  pluginsSource: any JSPluginsSource { get }
    /// Hides app specific implementation for host check
    func nativeApp(for host: CottonBase.Host) -> String?
    /// Hides app specific feature for JS value
    func isJavaScriptEnabled() async -> Bool
    /// Hides app specific feature value for DNS over HTTPs
    func isDohEnabled() async -> Bool
    /// Hides app specific feature value for Native app redirects
    func allowNativeAppRedirects() async -> Bool
    /// Wrapper for feature value from specific app
    func appAsyncApiTypeValue() async -> AsyncApiType
}
