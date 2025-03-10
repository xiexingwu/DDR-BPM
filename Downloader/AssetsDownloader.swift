//
//  Downloader.swift
//  DDR BPM
//
//  Created by Michael Xie on 17/6/2022.
//

import Foundation
import SwiftUI
import ZIPFoundation

private let STORE = "https://ddrbpm.com/"
private let ALL_SONGS_FILE = "all_songs.txt"
private let COURSES_FILE = "courses.json"
private let DATA_ZIP = "data.zip"
private let JACKETS_ZIP = "jackets.zip"

let ASSETS_SIZE = "100 MB"

extension String: Error {}

enum ModelError: Error {
    case missingViewModel
    case missingModelData
}

enum URLErrors: Error {
    case badURL
}

enum EtagStore {
    case data
    case jackets
}

class AssetsDownloader: NSObject, ObservableObject, URLSessionTaskDelegate {
    private var fileManager = FileManager()
    private var viewModel: ViewModel?
    private var modelData: ModelData?

    static let shared = AssetsDownloader()

    func linkViewModel(_ viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    func linkModelData(_ modelData: ModelData) {
        self.modelData = modelData
    }

    func downloadFromStore(_ urlString: String) async throws -> (URL, URLResponse) {

        guard
            let url = URL(
                string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                    ?? "")
        else {
            defaultLogger.error("==========Failed to make url to \(urlString)")
            throw URLErrors.badURL
        }

        return try await URLSession.shared.download(from: url)

        // var request = URLRequest(url: url)
        //
        // request.httpMethod = "GET"
        //
        // defaultLogger.debug("downloading: \(urlString)")
        // return try await URLSession.shared.download(for: request)
    }

    func getEtagFromStore(_ urlString: String) async throws -> String {
        guard
            let url = URL(
                string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                    ?? "")
        else {
            defaultLogger.error("==========Failed to make url to \(urlString)")
            throw URLErrors.badURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = "HEAD"

        defaultLogger.debug("requesting Etag from: \(urlString)")
        let (_, response) = try await URLSession.shared.bytes(for: request)

        guard let etag = (response as? HTTPURLResponse)?.allHeaderFields["Etag"] as? String
        else {
            defaultLogger.error("Failed to fetch etag")
            defaultLogger.error("\(response.description)")
            return ""
        }

        return etag
    }
}

/* check and download assets */
extension AssetsDownloader {

    func checkUpdate() async -> UpdateStatus {
        do {
            var etag: String

            etag = try await getEtagFromStore(STORE + DATA_ZIP)
            let dataUpdated = (etag != modelData?.dataEtag)
            defaultLogger.debug("new data etag: \(etag)")
            defaultLogger.debug("old data etag: \(self.modelData?.dataEtag)")
            defaultLogger.debug("Update needed: \(dataUpdated)")

            etag = try await getEtagFromStore(STORE + JACKETS_ZIP)
            let jacketsUpdated = (etag != modelData?.jacketsEtag)
            defaultLogger.debug("new jackets etag: \(etag)")
            defaultLogger.debug("old jackets etag: \(self.modelData?.jacketsEtag)")
            defaultLogger.debug("Update needed: \(jacketsUpdated )")

            return dataUpdated || jacketsUpdated ? .available : .notavailable
        } catch {
            defaultLogger.error("Failed to check update")
            return .available
        }
    }

    // func updateAssets() {
    //     downloadDataZipTask(
    //         resource_path: STORE + DATA_ZIP, destination: SONGS_FOLDER_URL,
    //         etagStore: .data)
    //     downloadDataZipTask(
    //         resource_path: STORE + DATA_ZIP, destination: SONGS_FOLDER_URL,
    //         etagStore: .jackets)
    // }

    func updateAssets() async -> UpdateStatus {
        do {
            let dataEtag = try await downloadDataZip(
                resource_path: STORE + DATA_ZIP, destination: SONGS_FOLDER_URL)
            DispatchQueue.main.async {
                self.modelData?.dataEtag = dataEtag
            }
            defaultLogger.debug("set dataEtag: \(dataEtag)")

            let jacketsEtag = try await downloadDataZip(
                resource_path: STORE + JACKETS_ZIP, destination: JACKETS_FOLDER_URL)
            DispatchQueue.main.async {
                self.modelData?.jacketsEtag = jacketsEtag
            }
            defaultLogger.debug("set jacketsEtag: \(jacketsEtag)")

            return .success
        } catch {
            defaultLogger.error("Failed to download and unzip assets: \(error)")
            return .fail
        }
    }

    func downloadDataZip(resource_path: String, destination: URL) async throws -> String {
        let (url, response) = try await downloadFromStore(resource_path)
        if !responseSucceeded(response) {
            throw "Failed to download \(url)"
        }
        let savedZipURL = url
        // let savedZipURL = APPDATA_FOLDER_URL.appendingPathComponent("tmp.zip")
        // try? fileManager.removeItem(at: savedZipURL)
        // try fileManager.moveItem(at: url, to: savedZipURL)

        let fileAttribute = try fileManager.attributesOfItem(atPath: savedZipURL.path)
        let fileSize = fileAttribute[FileAttributeKey.size] as! Int64
        let fileType = fileAttribute[FileAttributeKey.type] as! String
        let filecreationDate = fileAttribute[FileAttributeKey.creationDate] as! Date
        let fileExtension = savedZipURL.pathExtension

        defaultLogger.debug(
            "Name: \(savedZipURL), Size: \(fileSize), Type: \(fileType), Date: \(filecreationDate), Extension: \(fileExtension)"
        )
        defaultLogger.debug(
            "Hash: \(try? hashFile(savedZipURL).description)"
        )

        defaultLogger.debug("Preparing to unzip \(savedZipURL) to \(destination)")
        try? fileManager.removeItem(at: destination)
        defaultLogger.debug("Removed directory: \(destination)")
        try? fileManager.createDirectory(
            at: destination, withIntermediateDirectories: true, attributes: nil)
        defaultLogger.debug("Created directory: \(destination)")
        // let fileURLs = try FileManager.default.contentsOfDirectory(
        //     at: destination, includingPropertiesForKeys: nil)
        // for fileURL in fileURLs {
        //     try fileManager.removeItem(at: fileURL)
        // }
        defaultLogger.debug("Unzipping: \(savedZipURL)")
        try fileManager.unzipItem(at: savedZipURL, to: destination)
        let etag = (response as? HTTPURLResponse)?.allHeaderFields["Etag"] as? String
        return etag ?? ""
    }

    func downloadDataZipTask(resource_path: String, destination: URL, etagStore: EtagStore) {

        let resource_url = URL(
            string: resource_path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                ?? "")!

        let downloadTask = URLSession.shared.downloadTask(with: resource_url) {
            urlOrNil, responseOrNil, errorOrNil in
            // check for and handle errors:
            // * errorOrNil should be nil
            // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299

            guard let zipURL = urlOrNil else { return }
            guard let response = responseOrNil else { return }
            do {
                try? self.fileManager.removeItem(at: destination)
                defaultLogger.debug("Removed directory: \(destination)")
                try? self.fileManager.createDirectory(
                    at: destination, withIntermediateDirectories: true, attributes: nil)
                defaultLogger.debug("Created directory: \(destination)")
                defaultLogger.debug("Unzipping: \(zipURL)")
                try self.fileManager.unzipItem(at: zipURL, to: destination)

                guard let etag = (response as? HTTPURLResponse)?.allHeaderFields["Etag"] as? String
                else { throw "failed to fetch etag" }

                switch etagStore {
                case .data:
                    self.modelData?.dataEtag = etag
                case .jackets:

                    self.modelData?.jacketsEtag = etag
                }
                defaultLogger.debug("set etag for \(resource_path): \(etag)")
            } catch {
                print("error in downloading and unzipping \(resource_path): \(error)")
            }
        }

        downloadTask.resume()
    }
}
