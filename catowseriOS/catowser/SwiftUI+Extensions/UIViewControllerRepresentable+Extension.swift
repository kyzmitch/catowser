//
//  UIViewControllerRepresentable+Extension.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/30/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI

@MainActor
protocol CatowserUIVCRepresentable: UIViewControllerRepresentable {
    var vcFactory: ViewControllerFactory { get }
}

extension CatowserUIVCRepresentable {
    var vcFactory: ViewControllerFactory {
        UIServiceRegistry.shared().vcFactory
    }
}
