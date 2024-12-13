//
//  DownloadError.swift
//  catowser
//
//  Created by Andrey Ermoshin on 09.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Foundation

/// Download error
public enum DownloadError: LocalizedError {
    case zombyInstance
    case noDocumentsDirectory
    case noAppGroupDirectory
    case failedCreateFileProviderFolder
    case noCorrectDownloadDestination
    case failedExcludeFromBackup(Error)
    case networkError(Error)
    case noHttpHeadersInResponse
    case noContentLengthHeader
    case stringToIntFailed
    case urlRequestInit(Error)

    public var description: String {
        switch self {
        case .failedExcludeFromBackup(let error):
            return "failed to exclude download url from backup: \(error)"
        case .networkError(let error):
            return "network error: \(error)"
        case .urlRequestInit(let error):
            return "failed to construct URLRequest: \(error)"
        default:
            return "\(self)"
        }
    }
}
