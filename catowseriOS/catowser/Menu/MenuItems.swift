//
//  MenuItems.swift
//  catowser
//
//  Created by Andrei Ermoshin on 3/13/24.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Foundation

extension String {
    static let globalSectionTtl: String = "ttl_global_menu"
    static let searchSectionTtl: String = "ttl_search_menu"
    static let devSectionTtl: String = "ttl_developer_menu"
    static let dohMenuTitle: String = "txt_doh_menu_item"
    static let jsMenuTitle: String = "txt_javascript_enabled"
    static let nativeAppRedirectTitle: String = "txt_native_app_redirect_enabled"
    static let dismissBtn: String = "btn_dismiss"
    static let tabAddTxt: String = "ttl_tab_positions"
    static let tabContentTxt: String = "ttl_tab_default_content"
    static let appAsyncApiTypeTxt: String = "ttl_app_async_method"
    static let webAutoCompleteSourceTxt: String = "ttl_web_search_auto_complete_source"
    static let appUIFrameworkTypeTxt: String = "ttl_app_ui_framework_type"
    static let observingApiTypeTxt: String = "ttl_app_observing_method"
}

enum CottonMenuItem {
    case tabAddPosition
    case defaultTabContent
    case webAutocompletionSource
    case asyncApi
    case uiFramework
    case observingApi
}
