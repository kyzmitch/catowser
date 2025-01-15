//
//  SearchSuggestionsViewController.swift
//  catowser
//
//  Created by Andrey Ermoshin on 22/02/2018.
//  Copyright © 2018 Cotton (former Catowser). All rights reserved.
//

import UIKit
import FeatureFlagsKit
import Combine
import CottonViewModels

fileprivate extension String {
    static let searchSuggestionCellId = "SearchSuggestionCellId"
}

/// View controller for suggestions view
/// Looks similar to the one in Safari
final class SearchSuggestionsViewController: UITableViewController {
    private let viewModel: any SearchSuggestionsViewModel

    private var state: SearchSuggestionsViewState = .waitingForQuery {
        didSet {
            tableView.reloadData()
        }
    }

    /// Combine cancellable for Concurrency Published property
    private var taskHandler: AnyCancellable?
    /// Delegate to handle suggestion selection
    private weak var delegate: SearchSuggestionsListDelegate?

    init(
        _ delegate: SearchSuggestionsListDelegate?,
        _ viewModel: any SearchSuggestionsViewModel
    ) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        // https://www.hackingwithswift.com/example-code/uikit/how-to-register-a-cell-for-uitableviewcell-reuse
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .searchSuggestionCellId)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        taskHandler?.cancel()
        taskHandler = viewModel.statePublisher.sink(receiveValue: onStateChange)

        // Also would be good to observe for the changes in settings
        // to notify user to close and open this search table
        // to re-create view model with recently selected auto complete source.
        // Need to update FeatureManager enum features
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        taskHandler?.cancel()
    }

    private func onStateChange(_ state: SearchSuggestionsViewState) {
        guard self.state != state else {
            return
        }
        self.state = state
    }
}

extension SearchSuggestionsViewController /* UITableViewDataSource */ {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return state.sectionsNumber
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        state.sectionTitle(section: section)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return state.rowsCount(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .searchSuggestionCellId, for: indexPath)
        cell.textLabel?.text = state.value(from: indexPath.row, section: indexPath.section)
        return cell
    }
}

extension SearchSuggestionsViewController /* UITableViewDelegate */ {
    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let text = state.value(from: indexPath.row, section: indexPath.section) else {
            return
        }

        let content: SuggestionType
        switch indexPath.section {
        case 0:
            content = .knownDomain(text)
        case 1:
            content = .suggestion(text)
        default:
            return
        }
        Task {
            try? await delegate?.searchSuggestionDidSelect(content)
        }
    }
}

extension SearchSuggestionsViewController: SearchSuggestionsControllerInterface {
    func prepareSearch(for searchQuery: String) async {
        await viewModel.fetchSuggestions(searchQuery)
    }
}
