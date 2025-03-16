import Foundation
import UIKit
import ZIPFoundation

extension String: Error {}  // Allows throwing strings

enum EtagStore {
    case data
    case jackets
}

class BackgroundDownloader: NSObject {
    static let shared = BackgroundDownloader()

    // Background session
    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(
            withIdentifier: "com.ddrbpm.backgrounddownloader")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    // Track data associated to each download task
    struct TaskData {
        var etagStore: EtagStore
        var modelData: ModelData
        var viewModel: ViewModel
        var isLast: Bool
    }
    private var taskData: [Int: TaskData] = [:]

}

// Interface to manage tasks
extension BackgroundDownloader {
    func downloadAsset(
        etagStore: EtagStore, viewModel: ViewModel, modelData: ModelData, isLast: Bool = false
    ) {
        let urlString: String = {
            switch etagStore {
            case .data:
                return STORE + DATA_ZIP
            case .jackets:
                return STORE + JACKETS_ZIP
            }
        }()
        guard
            let url = URL(
                string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        else {
            defaultLogger.error("Failed to make download url from \(urlString)")
            return
        }

        let downloadTask = backgroundSession.downloadTask(with: url)

        // Store references
        let id = downloadTask.taskIdentifier
        taskData[id] = TaskData(
            etagStore: etagStore, modelData: modelData, viewModel: viewModel, isLast: isLast)

        // Start the download
        downloadTask.resume()

        let taskName: String = {
            switch etagStore {
            case .data:
                return "Data"
            case .jackets:
                return "Jackets"
            }
        }()
        defaultLogger.debug("Initiated download task for \(taskName) with id \(id)")
    }

    // Cleanup
    private func cleanupTask(_ downloadTask: URLSessionDownloadTask) {
        let id = downloadTask.taskIdentifier
        taskData.removeValue(forKey: id)
    }
}

extension BackgroundDownloader: URLSessionDownloadDelegate {

    // completion handler
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let response = downloadTask.response as? HTTPURLResponse else { return }

        let id = downloadTask.taskIdentifier
        guard let data = taskData[id] else { return }

        let destinationUrl = {
            switch data.etagStore {
            case .data:
                return SONGS_FOLDER_URL
            case .jackets:
                return JACKETS_FOLDER_URL
            }
        }()

        do {
            try unzip(zipUrl: location, destinationUrl: destinationUrl)
            try setEtag(
                response: response,
                etagStore: data.etagStore,
                modelData: data.modelData
            )
            if data.isLast {
                DispatchQueue.main.async {
                    data.modelData.loadSongs()
                    data.viewModel.updateStatus = .success
                }
            }

        } catch {
            defaultLogger.error("Error processing download: \(error.localizedDescription)")
            DispatchQueue.main.async {
                data.viewModel.updateStatus = .fail
            }
        }

        // Clean up
        cleanupTask(downloadTask)
    }

    // progress update
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {

        let id = downloadTask.taskIdentifier
        guard let data = taskData[id] else { return }
        guard let response = downloadTask.response as? HTTPURLResponse else { return }

        guard let contentLength = response.allHeaderFields["Content-Length"] as? String else {
            return
        }
        defaultLogger.debug("download progress: \(totalBytesWritten) / \(contentLength)")

        let bytesExpected =
            totalBytesExpectedToWrite != -1
            ? totalBytesExpectedToWrite
            : Int64(contentLength) ?? 0

        DispatchQueue.main.async {
            data.viewModel.downloadProgressBytes = (
                totalBytesWritten, bytesExpected
            )
        }
    }

    // Error handler
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        guard let downloadTask = task as? URLSessionDownloadTask else { return }

        if let error = error {
            print(
                "Download failed for \(downloadTask.taskIdentifier): \(error.localizedDescription)")
            cleanupTask(downloadTask)
        }
    }

}

/* Utilities */
func unzip(zipUrl: URL, destinationUrl: URL) throws {
    let fileManager = FileManager()

    try? fileManager.removeItem(at: destinationUrl)
    defaultLogger.debug("Removed directory: \(destinationUrl)")
    try? fileManager.createDirectory(
        at: destinationUrl, withIntermediateDirectories: true, attributes: nil)
    defaultLogger.debug("Created directory: \(destinationUrl)")
    defaultLogger.debug("Unzipping: \(zipUrl)")
    try fileManager.unzipItem(at: zipUrl, to: destinationUrl)
}

func setEtag(response: HTTPURLResponse, etagStore: EtagStore, modelData: ModelData) throws {

    guard let etag = response.allHeaderFields["Etag"] as? String
    else {
        defaultLogger.error("failed to fetch etag from response")
        throw "failed to fetch etag from response"
    }

    DispatchQueue.main.async {
        switch etagStore {
        case .data:
            modelData.dataEtag = etag
            return
        case .jackets:
            modelData.jacketsEtag = etag
            return
        }
    }
}

func fetchEtag(_ urlString: String) async throws -> String {
    guard
        let url = URL(
            string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                ?? "")
    else {
        defaultLogger.error("==========Failed to make url to \(urlString)")
        return ""
    }

    var request = URLRequest(url: url)

    request.httpMethod = "HEAD"

    defaultLogger.debug("requesting Etag for: \(urlString)")
    let (_, response) = try await URLSession.shared.bytes(for: request)

    guard let etag = (response as? HTTPURLResponse)?.allHeaderFields["Etag"] as? String
    else {
        defaultLogger.error("Failed to fetch etag")
        defaultLogger.error("\(response.description)")
        return ""
    }

    return etag
}
