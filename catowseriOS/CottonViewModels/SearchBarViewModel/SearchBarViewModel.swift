//
//  SearchBarViewModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/4/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonBase
import CoreBrowser
import CottonNetworking
import CottonUseCases
import UIKit
import ViewModelKit

/// Base search bar view model class
public typealias SearchBarViewModel = BaseViewModel<
    SearchBarState<SearchBarStateContextProxy>,
    SearchBarAction,
    SearchBarStateContextProxy
>

/// Combined base class with additional protocol,
/// because this combonation can't be used as a generic parameter (e.g. in SearchBarLegacyView)
public typealias SearchBarViewModelWithDelegates = SearchBarViewModel & SearchBarDelegateHolder

/// View model itself can't implement that delegate protocol because of NSObject inheritance,
/// so that, using separate interface for it.
public protocol SearchBarDelegateHolder {
    var searchBarDelegate: UISearchBarDelegate? { get }
    var searchSuggestionsDelegate: SearchSuggestionsListDelegate? { get }
}

/// An analog of existing SearchBar coordinator, but for SwiftUI
/// and at the same time it implements `SearchSuggestionsListDelegate`
/// and `UISearchBarDelegate` which couldn't be implemented in SwiftUI view.
/// This class is only needed for SwiftUI mode when it uses old UKit view controller.
@MainActor public final class SearchBarViewModelImpl: @preconcurrency SearchBarViewModelWithDelegates {
    /// Write tabs use case
    private let writeTabsUseCase: WriteTabsUseCase
    /// Search autocomplete use case
    private let autocompletionUseCase: AutocompleteSearchUseCase
    /// App side context
    private let appContext: SearchBarContext
    /// Delegate (to not be forced to subclass NSObject, because there is no multiple inheritance)
    public var searchBarDelegate: UISearchBarDelegate?
    /// Search suggestions property
    public var searchSuggestionsDelegate: SearchSuggestionsListDelegate? {
        self
    }

    public init(
        _ writeTabsUseCase: WriteTabsUseCase,
        _ autocompletionUseCase: AutocompleteSearchUseCase,
        _ appContext: SearchBarContext
    ) {
        self.writeTabsUseCase = writeTabsUseCase
        self.autocompletionUseCase = autocompletionUseCase
        self.appContext = appContext
        super.init()
        searchBarDelegate = SearchBarDelegateImpl(viewModel: self)
    }
    
    public override var context: Context? {
        SearchBarStateContextProxy(subject: self)
    }
    
    private func replaceTab(
        with url: URL,
        with suggestion: String? = nil,
        _ isJSEnabled: Bool
    ) async throws {
        let settings = Site.Settings(
            isPrivate: false,
            blockPopups: appContext.blockPopups,
            isJSEnabled: isJSEnabled,
            canLoadPlugins: true
        )
        guard let site = Site(url, suggestion, settings) else {
            throw SearchBarError.failToInitNewSiteValue
        }
        try await writeTabsUseCase.replaceSelected(.site(site))
    }
}

// MARK: - SearchSuggestionsListDelegate & SearchBarStateContext

extension SearchBarViewModelImpl: SearchBarStateContext {
    public func searchSuggestionDidSelect(_ content: SuggestionType) async throws {
        let isJSEnabled = await appContext.isJSEnabled
        switch content {
        case .looksLikeURL(let likeURL):
            guard let url = URL(string: likeURL) else {
                throw SearchBarError.looksLikeUrlButNotExactly(likeURL)
            }
            try await replaceTab(with: url, with: nil, isJSEnabled)
        case .knownDomain(let domain):
            guard let url = URL(string: "https://\(domain)") else {
                throw SearchBarError.failToCreatUrlFromDomain
            }
            try await replaceTab(with: url, with: nil, isJSEnabled)
        case .suggestion(let suggestion):
            let source = await appContext.webAutocompletionSourceValue
            let url = try await autocompletionUseCase.createSearchURL(
                source,
                suggestion
            )
            try await replaceTab(with: url, with: suggestion, isJSEnabled)
        }
    }
}
