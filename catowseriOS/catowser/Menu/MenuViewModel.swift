//
//  MenuViewModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 5/26/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

#if canImport(Combine)
@preconcurrency import Combine
#endif
import CottonBase
import CottonData
import CoreBrowser
import FeatureFlagsKit
import CottonDataServices

enum BrowserMenuStyle {
    case withSiteMenu(Host, Site.Settings)
    case onlyGlobalMenu
}

@MainActor
protocol DeveloperMenuPresenter: AnyObject {
    func emulateLinkTags()
    /// This method is not for dev only and should be available in any build types
    func host(_ host: Host, willUpdateJsState enabled: Bool)
}

@MainActor
final class MenuViewModel: ObservableObject {
    private struct State {
        let tabContentRowValue: CoreBrowser.Tab.ContentType
        let webAutocompleteRowValue: WebAutoCompletionSource
        let tabAddPositionRowValue: AddedTabPosition
        let asyncApiRowValue: AsyncApiType
        let uiFrameworkRowValue: UIFrameworkType
        let observingApiRowValue: ObservingApiType
    }
    
    // MARK: - global settings

    @Published var isDohEnabled: Bool
    @Published var isJavaScriptEnabled: Bool
    @Published var nativeAppRedirectEnabled: Bool
    
    // MARK: - Allow to update text view content dynamically

    @Published var tabContentRowValue: CoreBrowser.Tab.ContentType = .favorites
    @Published var webAutocompleteRowValue: WebAutoCompletionSource = .google
    @Published var tabAddPositionRowValue: AddedTabPosition = .afterSelected
    @Published var asyncApiRowValue: AsyncApiType = .asyncAwait
    @Published var uiFrameworkRowValue: UIFrameworkType = .uiKit
    @Published var observingApiRowValue: ObservingApiType = .observerDesignPattern

    // MARK: - specific tab settings

    @Published var isTabJSEnabled: Bool

    // MARK: - disposables

    private var dohChangesCancellable: AnyCancellable?
    private var jsEnabledOptionCancellable: AnyCancellable?
    private var tabjsEnabledCancellable: AnyCancellable?
    private var nativeAppRedirectCancellable: AnyCancellable?

    // MARK: - state

    let style: BrowserMenuStyle
    private var host: Host? {
        if case let .withSiteMenu(host, _) = style {
            return host
        }
        return nil
    }
    private var siteSettings: Site.Settings? {
        if case let .withSiteMenu(_, settings) = style {
            return settings
        }
        return nil
    }

    // MARK: - delegates

    weak var developerMenuPresenter: DeveloperMenuPresenter?

    // MARK: - text properties

    var siteSectionTitle: String {
        // site section is only available for site menu
        return .localizedStringWithFormat(.siteSectionTtl, host?.rawString ?? "")
    }

    let viewTitle: String = .menuTtl

    // MARK: - init

    /// Depends on menu style and initial values of feaure flags
    init(_ menuStyle: BrowserMenuStyle,
         _ isDohEnabled: Bool,
         _ isJavaScriptEnabled: Bool,
         _ nativeAppRedirectEnabled: Bool) {
        style = menuStyle
        switch menuStyle {
        case .withSiteMenu(_, let settings):
            isTabJSEnabled = settings.isJSEnabled
        case .onlyGlobalMenu:
            isTabJSEnabled = true
        }
        self.isDohEnabled = isDohEnabled
        self.isJavaScriptEnabled = isJavaScriptEnabled
        self.nativeAppRedirectEnabled = nativeAppRedirectEnabled

        // for some reason below observers gets triggered
        // right away in init
        dohChangesCancellable = $isDohEnabled
            .dropFirst()
            .sink { value in
                Task {
                    await FeatureManager.shared.setFeature(.dnsOverHTTPSAvailable, value: value)
                }
            }
        jsEnabledOptionCancellable = $isJavaScriptEnabled
            .dropFirst()
            .sink { value in
                Task {
                    await FeatureManager.shared.setFeature(.javaScriptEnabled, value: value)
                }
            }
        tabjsEnabledCancellable = $isTabJSEnabled
            .sink(receiveValue: { [weak self] newValue in
                guard let self = self else {
                    return
                }
                guard case let .withSiteMenu(host, _) = self.style  else {
                    return
                }
                self.developerMenuPresenter?.host(host, willUpdateJsState: newValue)
            })
        nativeAppRedirectCancellable = $nativeAppRedirectEnabled
            .dropFirst()
            .sink { value in
                Task {
                    await FeatureManager.shared.setFeature(.nativeAppRedirect, value: value)
                }
            }
    }

    deinit {
        dohChangesCancellable?.cancel()
        jsEnabledOptionCancellable?.cancel()
        tabjsEnabledCancellable?.cancel()
    }

    // MARK: - dev/debug menu handlers

    func emulateLinkTags() {
        developerMenuPresenter?.emulateLinkTags()
    }
    
    // MARK: - public interface
    
    func setTabAddPosition(_ selected: AddedTabPosition) {
        Task {
            await FeatureManager.shared.setFeature(.tabAddPosition, value: selected)
        }
        tabAddPositionRowValue = selected
    }
    
    func setTabContent(_ selected: CoreBrowser.Tab.ContentType) {
        Task {
            await FeatureManager.shared.setFeature(.tabDefaultContent, value: selected)
        }
        tabContentRowValue = selected
    }
    
    func setAutocomplete(_ selected: WebAutoCompletionSource) {
        Task {
            await FeatureManager.shared.setFeature(.webAutoCompletionSource, value: selected)
        }
        webAutocompleteRowValue = selected
    }
    
    func setAsyncApi(_ selected: AsyncApiType) {
        Task {
            await FeatureManager.shared.setFeature(.appDefaultAsyncApi, value: selected)
        }
        asyncApiRowValue = selected
    }
    
    func setUiFramework(_ selected: UIFrameworkType) {
        Task {
            await FeatureManager.shared.setFeature(.appDefaultUIFramework, value: selected)
        }
        uiFrameworkRowValue = selected
    }
    
    func setObservingApi(_ selected: ObservingApiType) {
        Task {
            await FeatureManager.shared.setFeature(
                .observingApi,
                value: selected
            )
        }
        observingApiRowValue = selected
    }
    
    func load() async {
        async let tabValue = FeatureManager.shared.tabDefaultContentValue()
        async let webValue = FeatureManager.shared.webSearchAutoCompleteValue()
        async let addValue = FeatureManager.shared.tabAddPositionValue()
        async let asyncValue = FeatureManager.shared.appAsyncApiTypeValue()
        async let uiValue = FeatureManager.shared.appUIFrameworkValue()
        async let observingValue = FeatureManager.shared.observingApiTypeValue()
        
        let state = await State(
            tabContentRowValue: tabValue,
            webAutocompleteRowValue: webValue,
            tabAddPositionRowValue: addValue,
            asyncApiRowValue: asyncValue,
            uiFrameworkRowValue: uiValue,
            observingApiRowValue: observingValue
        )
        tabContentRowValue = state.tabContentRowValue
        webAutocompleteRowValue = state.webAutocompleteRowValue
        tabAddPositionRowValue = state.tabAddPositionRowValue
        asyncApiRowValue = state.asyncApiRowValue
        uiFrameworkRowValue = state.uiFrameworkRowValue
        observingApiRowValue = state.observingApiRowValue
    }
}

private extension String {
    static let siteSectionTtl = NSLocalizedString("ttl_site_menu", comment: "Menu for tab")
    static let menuTtl = NSLocalizedString("ttl_common_menu", comment: "")
}
