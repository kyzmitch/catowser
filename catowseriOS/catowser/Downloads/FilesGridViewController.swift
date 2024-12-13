//
//  FilesGridViewController.swift
//  catowser
//
//  Created by Andrei Ermoshin on 03/04/2019.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CoreBrowser
// needed for `Downloadable`
import CottonNetworking
import CottonPlugins

@MainActor
protocol FilesGridPresenter: AnyObject {
    func reloadWith(source: TagsSiteDataSource, completion: (() -> Void)?)
    func clearFiles()
}

@MainActor
protocol FileDownloadViewDelegate: AnyObject {
    func didRequestOpen(local url: URL, from sourceView: DownloadButtonCellView)
    func didPressDownload(callback: @escaping (FileDownloadViewModel?) -> Void)
}

final class FilesGridViewController: UITableViewController, CollectionViewInterface {
    private var backLayer: CAGradientLayer?

    fileprivate var filesDataSource: TagsSiteDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = Sizes.rowHeight
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        backLayer?.removeFromSuperlayer()
        let backLayer: CAGradientLayer = .lightBackgroundGradientLayer(bounds: view.bounds, lightTop: false)
        self.backLayer = backLayer
        tableView.layer.insertSublayer(backLayer, at: 0)
    }
}

fileprivate extension FilesGridViewController {
    struct Sizes {
        static let margin = CGFloat(8)
        static let imageMargin = CGFloat(14)
        static let rowHeight = CGFloat(160)
    }
}

// MARK: UITableViewDataSource

extension FilesGridViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesDataSource?.itemsCount ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(for: indexPath, type: DownloadButtonCellView.self)
        cell.selectionStyle = .none

        let tableW = tableView.bounds.width - Sizes.margin * 2 - Sizes.imageMargin * 2
        var desiredLabelW = tableW - cell.previewImageView.center.x
        desiredLabelW -= cell.previewImageView.bounds.width / 2 - cell.downloadButton.bounds.width
        cell.titleLabel.preferredMaxLayoutWidth = desiredLabelW

        cell.delegate = self

        guard let source = filesDataSource else { return cell }

        switch source {
        case .instagram(let nodes):
            let node = nodes[indexPath.item]
            cell.viewModel = FileDownloadViewModel(with: node, name: node.fileDescription)
            cell.mediaFilePreviewURL = node.thumbnailUrl
        case .htmlVideos(let tags):
            let tag = tags[indexPath.item]
            cell.viewModel = FileDownloadViewModel(with: tag, name: tag.fileDescription)
            cell.mediaFilePreviewURL = tag.poster
        }

        return cell
    }
}

// MARK: Files Greed Presenter

extension FilesGridViewController: FilesGridPresenter {
    func clearFiles() {
        filesDataSource = nil
        tableView.reloadData()
    }

    func reloadWith(source: TagsSiteDataSource, completion: (() -> Void)? = nil) {
        guard filesDataSource != source else {
            completion?()
            return
        }

        filesDataSource = source

        if let afterReloadClosure = completion {
            tableView.reloadData(afterReloadClosure)
        } else {
            tableView.reloadData()
        }
    }
}

// MARK: - File Download View Delegate

extension FilesGridViewController: FileDownloadViewDelegate {
    func didRequestOpen(local url: URL, from sourceView: DownloadButtonCellView) {
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.title = NSLocalizedString("ttl_video_share", comment: "Share video")

        if let popoverPresenter = activity.popoverPresentationController {
            popoverPresenter.permittedArrowDirections = .any
            // frame of button view can be used, because no transformations for it
            let btnFrame = sourceView.downloadButton.frame
            popoverPresenter.sourceRect = btnFrame
            popoverPresenter.sourceView = sourceView
        }
        // TODO: move to coordinator
        present(activity, animated: true)
    }

    func didPressDownload(callback: @escaping (FileDownloadViewModel?) -> Void) {
        // can be removed, but can be used if we want to provide
        // an interface for more than one links for the same resource
        callback(nil)
    }
}

/// Declaring following properties here, because type and protocol are from different frameworks.
/// So, this place is neutral.
extension InstagramVideoNode: @retroactive Downloadable {
    public var url: URL {
        return videoUrl
    }

    public var hostname: String {
        return "instagram.com"
    }
}

extension HTMLVideoTag: @retroactive Downloadable {
    public var url: URL {
        return src
    }

    public var hostname: String {
        return src.host ?? "unknown_host"
    }
}
