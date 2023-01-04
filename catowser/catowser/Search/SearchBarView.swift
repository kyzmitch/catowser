//
//  SearchBarV2View.swift
//  catowser
//
//  Created by Andrey Ermoshin on 10.12.2022.
//  Copyright © 2022 andreiermoshin. All rights reserved.
//

import SwiftUI

/// A search bar view
struct SearchBarView: View {
    @ObservedObject var model: SearchBarViewModel
    @Binding var stateBinding: SearchBarState
    
    var body: some View {
        PhoneSearchBarLegacyView(model: model, stateBinding: $stateBinding)
            .frame(height: CGFloat.searchViewHeight)
    }
}

private struct PhoneSearchBarLegacyView: UIViewControllerRepresentable {
    @ObservedObject var model: SearchBarViewModel
    @Binding var stateBinding: SearchBarState
    
    typealias UIViewControllerType = UIViewController
    
    private var vcFactory: ViewControllerFactory {
        ViewsEnvironment.shared.vcFactory
    }
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        let vc = vcFactory.deviceSpecificSearchBarViewController(model)
        // swiftlint:disable:next force_unwrapping
        return vc!.viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let interface = uiViewController as? SearchBarControllerInterface else {
            return
        }
        interface.changeState(to: stateBinding)
    }
}

#if DEBUG
struct SearchBarView_Previews: PreviewProvider {
    
    static var previews: some View {
        let model = SearchBarViewModel()
        let state: Binding<SearchBarState> = .init {
            .blankSearch
        } set: { _ in
            //
        }

        SearchBarView(model: model, stateBinding: state)
    }
}
#endif
