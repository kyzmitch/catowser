//
//  BrowserMenuView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 5/25/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonBase
import CoreBrowser
import FeaturesFlagsKit

struct BrowserMenuView: View {
    @ObservedObject private var model: MenuViewModel
    @Environment(\.presentationMode) var presentationMode

    // MARK: - State variables to be able to pop view automatically

    @State private var showingAppRestartAlert = false
    @State private var path: [CottonMenuItem] = []

    init(_ vm: MenuViewModel) {
        self.model = vm
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if case .withSiteMenu = model.style {
                    Section(header: Text(model.siteSectionTitle)) {
                        Toggle(isOn: $model.isTabJSEnabled) {
                            Text(LocalizedStringKey(.jsMenuTitle))
                        }
                    }
                }
                Section(header: Text(LocalizedStringKey(.globalSectionTtl))) {
                    Toggle(isOn: $model.isDohEnabled) {
                        Text(LocalizedStringKey(.dohMenuTitle))
                    }
                    Toggle(isOn: $model.isJavaScriptEnabled) {
                        Text(LocalizedStringKey(.jsMenuTitle))
                    }
                    NavigationLink(value: CottonMenuItem.tabAddPosition) {
                        MenuStatefullLabel(.tabAddTxt, model.tabAddPositionRowValue.description)
                    }
                    NavigationLink(value: CottonMenuItem.defaultTabContent) {
                        MenuStatefullLabel(.tabContentTxt, model.tabContentRowValue.description)
                    }
                }
                Section(header: Text(LocalizedStringKey(.searchSectionTtl))) {
                    NavigationLink(value: CottonMenuItem.webAutocompletionSource) {
                        MenuStatefullLabel(.webAutoCompleteSourceTxt, model.webAutocompleteRowValue.description)
                    }
                }
                #if DEBUG
                Section(header: Text(LocalizedStringKey(.devSectionTtl))) {
                    Toggle(isOn: $model.nativeAppRedirectEnabled) {
                        Text(LocalizedStringKey(.nativeAppRedirectTitle))
                    }
                    NavigationLink(value: CottonMenuItem.asyncApi) {
                        MenuStatefullLabel(.appAsyncApiTypeTxt, model.asyncApiRowValue.description)
                    }
                    NavigationLink(value: CottonMenuItem.uiFramework) {
                        MenuStatefullLabel(.appUIFrameworkTypeTxt, model.uiFrameworkRowValue.description)
                    }
                    NavigationLink(value: CottonMenuItem.observingApi) {
                        MenuStatefullLabel(.observingApiTypeTxt, model.observingApiRowValue.description)
                    }
                    Button("Simulate download resources") {
                        // Need to dismiss menu popover first if on Tablet
                        presentationMode.wrappedValue.dismiss()
                        model.emulateLinkTags()
                    }
                }
                #endif
            }
            .navigationDestination(for: CottonMenuItem.self, destination: { item in
                switch item {
                case .tabAddPosition:
                    BaseMenuView<AddedTabPosition>(viewModel: .init(model.tabAddPositionRowValue) { selected in
                        model.setTabAddPosition(selected)
                        path = []
                    })
                case .defaultTabContent:
                    BaseMenuView<CoreBrowser.Tab.ContentType>(viewModel: .init(model.tabContentRowValue) { selected in
                        model.setTabContent(selected)
                        path = []
                    })
                case .webAutocompletionSource:
                    BaseMenuView<WebAutoCompletionSource>(viewModel: .init(model.webAutocompleteRowValue) { selected in
                        model.setAutocomplete(selected)
                        path = []
                    })
                case .asyncApi:
                    BaseMenuView<AsyncApiType>(viewModel: .init(model.asyncApiRowValue) { selected in
                        model.setAsyncApi(selected)
                        path = []
                    })
                case .uiFramework:
                    BaseMenuView<UIFrameworkType>(viewModel: .init(model.uiFrameworkRowValue) { selected in
                        showingAppRestartAlert.toggle()
                        model.setUiFramework(selected)
                        path = []
                    })
                case .observingApi:
                    BaseMenuView<ObservingApiType>(viewModel: .init(model.observingApiRowValue) { selected in
                        showingAppRestartAlert.toggle()
                        model.setObservingApi(selected)
                        path = []
                    })
                }
            })
            .navigationBarTitle(Text(verbatim: model.viewTitle))
            .navigationBarItems(trailing: Button<Text>(LocalizedStringKey(.dismissBtn)) { presentationMode.wrappedValue.dismiss() }
            .foregroundColor(.black))
        }
        .alert(isPresented: $showingAppRestartAlert) {
            Alert(title: Text(verbatim: "App restart is required"),
                  dismissButton: .destructive(Text(verbatim: "Kill app process")) {
                    exit(0) // https://stackoverflow.com/a/8491688
                  })
        }
        .task {
            await model.load()
        }
    }
}

#if DEBUG
struct SiteMenuView_Previews: PreviewProvider {
    static var previews: some View {
        let host = try? Host(input: "example.com")
        let settings = Site.Settings(isPrivate: false,
                                     blockPopups: true,
                                     isJSEnabled: true,
                                     canLoadPlugins: true)
        // swiftlint:disable force_unwrapping
        let style: BrowserMenuStyle = .withSiteMenu(host!, settings)
        let model = MenuViewModel(style, false, false, false)
        return BrowserMenuView(model)
    }
}
#endif
