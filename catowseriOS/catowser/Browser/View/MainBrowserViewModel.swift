//
//  MainBrowserModel.swift
//  catowser
//
//  Created by Andrey Ermoshin on 14.12.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Combine
import SwiftUI
import CottonPlugins

@MainActor
final class MainBrowserViewModel<C: ContentCoordinatorsInterface>: ObservableObject {
    weak var coordinatorsInterface: C?
    /// Not a constant because can't be initialized in init
    lazy var jsPluginsBuilder: any JSPluginsSource = {
        JSPluginsBuilder().setBase(self).setInstagram(self)
    }()

    init(_ coordinatorsInterface: C?) {
        self.coordinatorsInterface = coordinatorsInterface
    }
}

extension MainBrowserViewModel: InstagramContentDelegate {
    func didReceiveVideoNodes(_ nodes: [InstagramVideoNode]) {}
}

extension MainBrowserViewModel: BasePluginContentDelegate {
    func didReceiveVideoTags(_ tags: [HTMLVideoTag]) {}
}
