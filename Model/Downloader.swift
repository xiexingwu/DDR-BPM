//
//  Downloader.swift
//  DDR BPM
//
//  Created by Michael Xie on 17/6/2022.
//

import Foundation
import SwiftUI
import Zip

private let GITHUB_TOKEN = "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"
private let JACKETS_URL = "https://github.com/xiexingwu/DDR-BPM-assets/releases/download/v1.0/jackets.zip"
//private let JACKETS_URL = "https://github.com/xiexingwu/DDR-BPM-assets/releases/download/v1.0/simfiles.zip"
let ASSETS_SIZE = "350 MB"

class AssetsDownloader: NSObject, ObservableObject, URLSessionTaskDelegate {
    private var viewModel : ViewModel?
    func linkViewModel(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    private var backgroundCompletionHandler : (() -> Void)?

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "BGSession")
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func downloadJacketsZip(){
        guard let url = URL(string: JACKETS_URL) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "GET"
        request.setValue("token \(GITHUB_TOKEN)", forHTTPHeaderField: "Authorization")
        
        let backgroundTask = session.downloadTask(with: request)

        backgroundTask.priority = 1.0

        backgroundTask.countOfBytesClientExpectsToSend = 1024 // max 1KB send
        backgroundTask.countOfBytesClientExpectsToReceive = 400 * 1024 * 1024 // max 400MB receive for jackets zip

        backgroundTask.taskDescription = "Download jackets.zip"

        backgroundTask.resume()
        viewModel?.downloadProgress = 0
    }

}

private func getMult(_ val: Int64) -> Int {
    // multiplicity: 1 -> KiB, 2-> MiB, 3-> GiB ...
    return Int(log(Float(val)) / log(1024))
}

private func getUnit(_ mult: Int) -> String {
    switch mult{
    case 0:
        return "B"
    case 1:
        return "KB"
    case 2:
        return "MB"
    case 3:
        return "GB"
    default:
        return "?B"
    }
}

private func readableBytes(_ bytes: Int64) -> String{
    let mult = getMult(bytes)
    let base = Int(pow(Float(1024), Float(mult)))
    let sig = Float(bytes)/Float(base)
    let sigStr = sig >= 10 ? String(format:"%.1f", sig) : String(format: "%.0f", sig)
    return sigStr + getUnit(mult)
}

extension AssetsDownloader: URLSessionDelegate, URLSessionDownloadDelegate {
    
    /* Update download progress */
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        DispatchQueue.main.async{
            self.viewModel?.downloadProgress = downloadTask.progress.fractionCompleted
            self.viewModel?.downloadProgressText = readableBytes(totalBytesWritten) + "/" + readableBytes(totalBytesExpectedToWrite)
        }
    }
    
    /* Unzip on completion */
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        print("Download finished: \(location.absoluteString)")
        
        let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? -1
        if statusCode >= 200 && statusCode <= 299 {
            do {
                let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                               in: .userDomainMask,
                                                               appropriateFor: nil,
                                                               create: false)
                let fname = downloadTask.originalRequest?.url?.lastPathComponent
                let savedZipURL = documentsURL.appendingPathComponent(fname ?? "tmp.zip")
                try FileManager.default.moveItem(at: location, to: savedZipURL)
//                let savedZipURL = documentsURL.appendingPathComponent("jackets.zip")
                
                print("Unzipping \(savedZipURL)")
                try Zip.unzipFile(savedZipURL,
                                  destination: documentsURL,
                                  overwrite: true,
                                  password: nil,
                                  progress: nil)
                try FileManager.default.removeItem(at: savedZipURL)

                DispatchQueue.main.async{
                    self.viewModel?.downloadStatus = .success
                    self.viewModel?.jacketsDownloaded = true
                    self.viewModel?.downloadProgress = -1
                }
            } catch {
                DispatchQueue.main.async{
                    self.viewModel?.downloadStatus = .fail
                    self.viewModel?.jacketsDownloaded = false
                    self.viewModel?.downloadProgress = -1
                }
                print("Failed to move/unzip downloaded file for task: \(String(describing: downloadTask.taskDescription))")
            }
        } else {
            DispatchQueue.main.async{
                self.viewModel?.downloadStatus = .fail
                self.viewModel?.jacketsDownloaded = false
                self.viewModel?.downloadProgress = -1
            }
            print("Failed download \(String(describing: downloadTask.taskDescription)) with code \(statusCode)")
        }
    }
    
    /* Print message on completion */
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let error = error {
            print("Download error: \(String(describing: error))")
        } else {
            print("downloadTask finished successfully: \(task)")
        }
    }

    /* Boilerplate for background download */
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
            backgroundCompletionHandler = completionHandler
    }

    /* Boilerplate for background download */
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AssetsDownloader,
                  let backgroundCompletionHandler = appDelegate.backgroundCompletionHandler
            else { return }
            backgroundCompletionHandler()
        }
    }
    
}

