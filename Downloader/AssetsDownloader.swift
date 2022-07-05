//
//  Downloader.swift
//  DDR BPM
//
//  Created by Michael Xie on 17/6/2022.
//

import Foundation
import SwiftUI
import Zip
import CryptoKit

typealias HashDigest = Insecure.SHA1Digest

private let GITHUB_TOKEN = "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"
private let JACKETS_URL = "https://github.com/xiexingwu/DDR-BPM-assets/releases/download/v1.0/jackets.zip"

private let GITHUB_RAW = "https://raw.githubusercontent.com/xiexingwu/DDR-BPM-assets/main/"
private func GITHUB_RAW_FILE (_ filename : String) -> String { GITHUB_RAW + filename }

private let GITHUB_LATEST = "https://github.com/xiexingwu/DDR-BPM-assets/releases/download/latest/"

private let ALL_SONGS_FILE = "all_songs.txt"
private let COURSES_FILE = "courses.txt"
private let HASHED_SONGS_FILE = "hashed_songs.txt"
private let HASHED_JACKETS_FILE = "hashed_jackets.txt"
private let HASHED_COURSES_FILE = "hashed_courses.txt"
private let DATA_ZIP = "data.zip"
private let JACKETS_ZIP = "jackets.zip"

let ASSETS_SIZE = "350 MB"


enum GitHubError: Error {
    case failedGet
}

enum ModelError: Error {
    case missingViewModel
    case missingModelData
}


class AssetsDownloader: NSObject, ObservableObject, URLSessionTaskDelegate {
    private var viewModel : ViewModel?
    private var modelData : ModelData?
    
    func linkViewModel(_ viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    func linkModelData(_ modelData: ModelData) {
        self.modelData = modelData
    }

    private var missingSongs: [String] = []
    private var obsoleteSongs: [String] = []
    private var updateCourses: Bool = false

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

    private func saveTmpFile(_ filename: String) -> ( (URL?, URLResponse?, Error?) -> Void ) {{
        urlOrNil, responseOrNil, errorOrNil in
        // check for and handle errors:
        // * errorOrNil should be nil
        // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299
        
        guard let fileURL = urlOrNil else { return }
        do {
            let tmpURL = FileManager.default.temporaryDirectory
            let savedURL = tmpURL.appendingPathComponent(filename)
            try FileManager.default.moveItem(at: fileURL, to: savedURL)
        } catch {
            print ("file to move file: \(error)")
        }
    }}
    
//    func defaultGithubDownloadTask(_ urlString: String, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) throws {
//        enum URLErrors : Error {
//            case badURL
//        }
//
//        guard let url = URL(string: urlString) else {
//            print("==========Failed to make url to \(urlString)")
//            throw URLErrors.badURL
//        }
//
//        var request = URLRequest(url: url)
//
//        request.httpMethod = "GET"
//        request.setValue("token \(GITHUB_TOKEN)", forHTTPHeaderField: "Authorization")
//
//        let downloadTask = URLSession.shared.downloadTask(with: request) { url, response, error in completionHandler(url, response, error) }
//        downloadTask.taskDescription = url.lastPathComponent
//
//        downloadTask.resume()
//    }
    
    func defaultGithubDownload(_ urlString: String) async throws -> (URL, URLResponse) {
        enum URLErrors : Error {
            case badURL
        }
        
        guard let url = URL(string: urlString) else {
            defaultLogger.error("==========Failed to make url to \(urlString)")
            throw URLErrors.badURL
        }
        
        var request = URLRequest(url: url)

        request.httpMethod = "GET"
        request.setValue("token \(GITHUB_TOKEN)", forHTTPHeaderField: "Authorization")
        
        return try await URLSession.shared.download(for: request)
    }
    
    func responseSucceeded(_ response: URLResponse) -> Bool {
        if let statusCode = (response as? HTTPURLResponse)?.statusCode {
            return statusCode >= 200 && statusCode <= 299
        } else {
            return false
        }
    }
    
    func readLines(contentsOf url: URL) throws -> [String] {
        enum ReadError: Error{
            case failedRead
        }
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            var lines = data.components(separatedBy: "\n")
            if let isEmpty = lines.last?.isEmpty {
                if isEmpty { lines.removeLast() }
            }
            return lines
        } catch {
            defaultLogger.error("Failed to readLines of \(String(describing: url))")
            throw ReadError.failedRead
        }
        
    }
    
    func checkUpdates() async {
        do {
            if modelData == nil {
                throw ModelError.missingModelData
            }
            if viewModel == nil {
                throw ModelError.missingViewModel
            }
            
            var needUpdate = false

            needUpdate = try await checkSongs() || needUpdate
            needUpdate = try await checkCourses() || needUpdate
            
            viewModel!.updateStatus = needUpdate ? .available : .success
            
        }
        catch ModelError.missingViewModel, ModelError.missingModelData {
            defaultLogger.error("Missing ViewModel or ModelData")
        }
        catch {
            defaultLogger.error("Failed to check updates")
            viewModel?.updateStatus = .fail
        }

    }

    private func checkSongs() async throws -> Bool {
        // Download files
        let (allSongsURL, allSongsResponse) = try await defaultGithubDownload(GITHUB_LATEST + ALL_SONGS_FILE)
        let (hashedSongsURL, hashedSongsResponse) = try await defaultGithubDownload(GITHUB_LATEST + HASHED_SONGS_FILE)
        if !responseSucceeded(allSongsResponse) || !responseSucceeded(hashedSongsResponse){
            throw GitHubError.failedGet
        }
        let allSongs = try readLines(contentsOf: allSongsURL)
        let hashedSongs = try readLines(contentsOf: hashedSongsURL)
        
        // Compare hashes
        missingSongs = []
        for (songName, songHash) in zip(allSongs, hashedSongs) {
            // missing song
            if getSongIndexByName(songName, modelData!.songs) == nil {
                defaultLogger.info("adding missing song: \(songName)")
                missingSongs.append(songName)
                continue
            }
            
            // incorrect hash
            let fileHash = getFileHash(appDataFolder + "/\(songName).json").description.components(separatedBy: " ").last!
            if fileHash != songHash {
                defaultLogger.info("Hash mismatch for \(songName):\n\tlocal: \(fileHash)\n\tsource: \(songHash)")
                missingSongs.append(songName)
            }
        }
        
        // Check removed songs
        obsoleteSongs = []
        for song in modelData!.songs {
            if !allSongs.contains(song.name) {
                obsoleteSongs.append(song.name)
            }
        }
        
        return (missingSongs.count + obsoleteSongs.count) > 0
    }
    
    private func checkCourses() async throws -> Bool {
        // Download files
        let (hashedCoursesURL, hashedCoursesResponse) = try await defaultGithubDownload(GITHUB_LATEST + HASHED_COURSES_FILE)
        if !responseSucceeded(hashedCoursesResponse) {
            throw GitHubError.failedGet
        }
        
        // Compare hashes
        let hashedCourses = try readLines(contentsOf: hashedCoursesURL)
        let fileHash = getFileHash(appCoursesFile).description.components(separatedBy: " ").last!
        
        updateCourses = fileHash == hashedCourses[0]
        return updateCourses
    }
    
    func fixAssets() async {}
    
    func validateAssets() async {}
    
//    // Check hash of all songs (obsolete)
//    func getSongsHash() -> [HashDigest] {
//        guard let dataFolder = Bundle.main.url(forResource: appDataFolder, withExtension: nil),
//              let dataFiles = FileManager.default.enumerator(at: dataFolder, includingPropertiesForKeys: nil)
//        else {
//            fatalError("Failed to find \(appDataFolder)")
//        }
//
//        return dataFiles.map {dataFile in
//            let hash = hashFile(dataFile as! URL)
//            defaultLogger.debug("\((dataFile as! URL).lastPathComponent): \(hash)")
//            return hash
//        }
//    }
    
    func getFileHash(_ filename: String) -> HashDigest {
        guard let dataFile = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Failed to find \(filename) for hashing")
        }
        
        let hash = hashFile(dataFile)
        return hash
    }
    
}



private func hashFile(_ file: URL) -> HashDigest {
    let data: Data
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(file):\n\(error)")
    }
    
    return Insecure.SHA1.hash(data: data)
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
        defaultLogger.info("Download finished: \(location.absoluteString)")
        
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
                
                defaultLogger.debug("Unzipping \(savedZipURL)")
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
                defaultLogger.error("Failed to move/unzip downloaded file for task: \(String(describing: downloadTask.taskDescription))")
            }
        } else {
            DispatchQueue.main.async{
                self.viewModel?.downloadStatus = .fail
                self.viewModel?.jacketsDownloaded = false
                self.viewModel?.downloadProgress = -1
            }
            defaultLogger.error("Failed download \(String(describing: downloadTask.taskDescription)) with code \(statusCode)")
        }
    }
    
    /* Print message on completion */
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let error = error {
            defaultLogger.error("Download error: \(String(describing: error))")
        } else {
            defaultLogger.debug("downloadTask finished successfully: \(task)")
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

