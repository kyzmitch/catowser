//
//  AppUIFrameworkTypeModel.swift
//  catowser
//
//  Created by Andrey Ermoshin on 10.12.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import FeaturesFlagsKit

typealias AppUIFrameworkTypeModel = BaseListViewModelImpl<UIFrameworkType>

extension BaseListViewModelImpl where EnumDataSourceType == UIFrameworkType {
    init(
        _ selected: EnumDataSourceType?,
        _ completion: @escaping PopClosure
    ) {
        self.init(NSLocalizedString("ttl_app_ui_framework_type", comment: ""),
                  completion,
                  selected)
    }
}

extension UIFrameworkType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .uiKit:
            return "UIKit"
        case .swiftUIWrapper:
            return "SwiftUI +/wraps UIKit"
        case .swiftUI:
            return "SwiftUI"
        }
    }
}

extension UIFrameworkType: Identifiable {
    public var id: RawValue {
        return self.rawValue
    }

    public typealias ID = RawValue
}
