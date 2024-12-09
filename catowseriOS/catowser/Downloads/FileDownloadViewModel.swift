//
//  FileDownloadViewModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 23/04/2019.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
@preconcurrency import ReactiveSwift
// needed for `Downloadable`
import CottonNetworking

@MainActor protocol FileDownloadDelegate: AnyObject {
    func didPressOpenFile(withLocal url: URL)
}

final class FileDownloadViewModel {
    fileprivate let batch: Downloadable

    fileprivate let downloadOutput: MutableProperty<DownloadState>
    fileprivate let resourceSizeOutput: MutableProperty<Int>

    lazy var downloadStateSignal: Signal<DownloadState, Never> = {
        return downloadOutput.signal
    }()

    /// resource size value is async and requires http request to be made
    lazy var resourceSizeSignal: Signal<Int, Never> = {
        return resourceSizeOutput.signal
    }()

    /// Current download state, can be used for download button state and progress indicator
    var downloadState: DownloadState {
        return downloadOutput.value
    }

    /// Name of media file which can be used for label content
    let labelText: String

    weak var delegate: FileDownloadDelegate?

    init(with batch: Downloadable, name: String) {
        self.batch = batch
        let downloadState: DownloadState
        if let fileURL = batch.fileAtDestination() {
            downloadState = .finished(fileURL)
        } else {
            downloadState = .initial
        }
        downloadOutput = .init(downloadState)
        resourceSizeOutput = .init(0)
        labelText = name

        fetchRemoteResourceInfo(url: batch.url)
            .observe(on: QueueScheduler.main)
            .startWithResult { [weak self] (result) in
                guard let self = self else {
                    assertionFailure("Fail to fetch file size - zomby self")
                    return
                }
                switch result {
                case .success(let bytesCount):
                    self.resourceSizeOutput.value = bytesCount
                case .failure(let error):
                    print("Fail to fetch file size: \(error.localizedDescription)")
                }
            }
    }

    func download() {
        downloadOutput.value = .started

        CottonNetworking.download(file: batch)
            .observe(on: QueueScheduler.main)
            .startWithResult { [weak self] (result) in
                guard let self = self else {
                    assertionFailure("Fail to start file download - zomby self")
                    return
                }
                switch result {
                case .success(let value):
                    switch value {
                    case .progress(let progress):
                        let converted = CGFloat(progress.fractionCompleted)
                        self.downloadOutput.value = .in(progress: converted)
                    case .complete(let localURL):
                        self.downloadOutput.value = .finished(localURL)
                    @unknown default:
                        fatalError("Not handled progress case")
                    }
                case .failure(let error):
                    print("download error: \(error)")
                    self.downloadOutput.value = .error(error)
                }
            }
    }
}

enum DownloadState {
    case initial
    case started
    case `in`(progress: CGFloat)
    case finished(URL)
    case error(Error)
}
