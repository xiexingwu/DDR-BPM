//
//  Downloader.swift
//  DDR BPM
//
//  Created by Michael Xie on 17/6/2022.
//

import Foundation
import Zip
import SwiftUI

private let GITHUB_RAW = "https://raw.githubusercontent.com/xiexingwu/DDR-BPM-assets/main/"
private func GITHUB_RAW_SONG (_ songName : String) -> String { GITHUB_RAW + "data/" + songName + ".json" }
private func GITHUB_RAW_JACKET (_ songName : String) -> String { GITHUB_RAW + "jackets-lowres/" + songName + "-jacket.png" }

private let GITHUB_LATEST = "https://github.com/xiexingwu/DDR-BPM-assets/releases/download/latest/"

private let ALL_SONGS_FILE = "all_songs.txt"
private let COURSES_FILE = "courses.json"
private let HASHED_SONGS_FILE = "hashed_songs.txt"
private let HASHED_JACKETS_FILE = "hashed_jackets.txt"
private let HASHED_COURSES_FILE = "hashed_courses.txt"
private let DATA_ZIP = "data.zip"
private let JACKETS_ZIP = "jackets.zip"

let ASSETS_SIZE = "40 MB"


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
    
    static let shared = AssetsDownloader()
    
    func linkViewModel(_ viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    func linkModelData(_ modelData: ModelData) {
        self.modelData = modelData
    }

    /* Foreground updating for singular assets */
    var missingSongs: [String] = []
    var missingJackets: [String] = []
    var obsoleteSongs: [String] = []
    var changedCourses: Bool = false

    var fix : Bool = false
    var fixesNeeded : Int = 0
    var fixes : Int = 0
    
    func defaultGithubDownload(_ urlString: String) async throws -> (URL, URLResponse) {
        enum URLErrors : Error {
            case badURL
        }
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        else {
            defaultLogger.error("==========Failed to make url to \(urlString)")
            throw URLErrors.badURL
        }
        
        var request = URLRequest(url: url)

        request.httpMethod = "GET"
        request.setValue("token \(GITHUB_TOKEN)", forHTTPHeaderField: "Authorization")
        
        defaultLogger.debug("downloading: \(urlString)")
        return try await URLSession.shared.download(for: request)
    }

    /* Background downloader for jackets */
    private var backgroundCompletionHandler : (() -> Void)?

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "BGSession")
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

}

/* Update assets - foreground one-by-one */
extension AssetsDownloader {
    
    func updateAssets(fix: Bool = false) async {
        do {
            if modelData == nil {
                throw ModelError.missingModelData
            }
            if viewModel == nil {
                throw ModelError.missingViewModel
            }
            
            self.fix = fix;
            fixes = 0

            DispatchQueue.main.async{
                if self.fix {
                    self.viewModel!.assetsStatus = .progressing
                } else {
                    self.viewModel!.updateStatus = .progressing
                }
            }


            var success : Bool = true
            if changedCourses{
                success = await updateCourses() && success
                fixes += 1
                DispatchQueue.main.async{
                    if fix{
                        self.viewModel!.assetsProgressText = "\(self.fixes)/\(self.fixesNeeded)"
                    } else {
                        self.viewModel!.updateProgressText = "\(self.fixes)/\(self.fixesNeeded)"
                    }
                }
            }
            
            for songName in missingSongs {
                success = await downloadRawSong(songName) && success
                fixes += 1
                if viewModel!.jacketsDownloaded {
                    success = await downloadRawJacket(songName) && success
                    fixes += 1
                }
                DispatchQueue.main.async{
                    if fix{
                        self.viewModel!.assetsProgressText = "\(self.fixes)/\(self.fixesNeeded)"
                    } else {
                        self.viewModel!.updateProgressText = "\(self.fixes)/\(self.fixesNeeded)"
                    }
                }
            }
            
            if viewModel!.jacketsDownloaded {
                for songName in missingJackets {
                    success = await downloadRawJacket(songName) && success
                    fixes += 1
                    DispatchQueue.main.async{
                        if fix{
                            self.viewModel!.assetsProgressText = "\(self.fixes)/\(self.fixesNeeded)"
                        } else {
                            self.viewModel!.updateProgressText = "\(self.fixes)/\(self.fixesNeeded)"
                        }
                    }
                }
            }
            
            for songName in obsoleteSongs {
                success = deleteSong(songName) && success
            }

            // Finalise updates
            switch (fix, success){
            case (true, true):
                DispatchQueue.main.async{
                    self.modelData!.loadData()
                    self.viewModel!.assetsStatus = .success
                }
            case (true, false):
                DispatchQueue.main.async{
                    self.viewModel!.assetsStatus = .fail
                }
            case (false, true):
                DispatchQueue.main.async{
                    self.modelData!.loadData()
                        self.viewModel!.updateStatus = .success
                }
            case (false, false):
                DispatchQueue.main.async{
                    self.viewModel!.updateStatus = .fail
                }
            }

            DispatchQueue.main.async{
                if fix{
                    self.viewModel!.assetsProgressText = ""
                } else {
                    self.viewModel!.updateProgressText = ""
                }
            }
        }
        catch ModelError.missingViewModel, ModelError.missingModelData {
            defaultLogger.error("Missing ViewModel or ModelData")
        }
        catch {
            defaultLogger.error("Failed to update Assets.")
        }

    }
    
    func downloadRawSong(_ songName: String) async -> Bool {
        do {
            // Download files
            let (url, response) = try await defaultGithubDownload(GITHUB_RAW_SONG(songName))
            if !responseSucceeded(response) {
                throw GitHubError.failedGet
            }
            
            // Move files
            let songURL = SONG_FILE_URL(songName)
            if FileManager.default.fileExists(atPath: songURL.path){
                try FileManager.default.removeItem(at: songURL)
            }

            try FileManager.default.moveItem(at: url, to: songURL)
            
            return true
        }
        catch GitHubError.failedGet {
            defaultLogger.error("Failed to download file: \(GITHUB_RAW_SONG(songName))")
            return false
        }
        catch {
            defaultLogger.error("Failed to move file: \(songName).json")
            return false
        }
    }
    
    func downloadRawJacket(_ songName: String) async -> Bool {
        do {
            // Download files
            let (url, response) = try await defaultGithubDownload(GITHUB_RAW_JACKET(songName))
            if !responseSucceeded(response) {
                throw GitHubError.failedGet
            }
            
            // Move files
            let jacketURL = JACKET_FILE_URL(songName)
            if FileManager.default.fileExists(atPath: jacketURL.path){
                try FileManager.default.removeItem(at: jacketURL)
            }
            try FileManager.default.moveItem(at: url, to: jacketURL)
            
            // if called due to missingSongs, remove from missingJackets to avoid double download
            if let i = missingJackets.firstIndex(where: {$0 == songName}) {
                missingJackets.remove(at: i)
            }
            
            return true
        }
        catch GitHubError.failedGet {
            defaultLogger.error("Failed to download file: \(GITHUB_RAW_JACKET(songName))")
            return false
        }
        catch {
            defaultLogger.error("Failed to move file: \(songName)-jacket.png: \(error.localizedDescription)")
//            defaultLogger.error("\(error.localizedDescription)")
//            print("error:\(error)")
            return false
        }
        
    }
    
    func updateCourses() async -> Bool {
        do {
            // Download files
            let (url, response) = try await defaultGithubDownload(GITHUB_LATEST + COURSES_FILE)
            if !responseSucceeded(response) {
                throw GitHubError.failedGet
            }
            
            // Move files
            if FileManager.default.fileExists(atPath: COURSES_FILE_URL.path){
                try FileManager.default.removeItem(at: COURSES_FILE_URL)
            }
            try FileManager.default.moveItem(at: url, to: COURSES_FILE_URL)
            
            return true
        }
        catch GitHubError.failedGet {
            defaultLogger.error("Failed to download courses file")
            return false
        }
        catch {
            defaultLogger.error("Failed to update courses.")
            return false
        }
    }

    func deleteSong(_ songName: String) -> Bool {
        do {
            try FileManager.default.removeItem(at: SONG_FILE_URL(songName))
            if viewModel!.jacketsDownloaded
                && FileManager.default.fileExists(atPath: JACKET_FILE_URL(songName).path){
                try FileManager.default.removeItem(at: JACKET_FILE_URL(songName))
            }
            return true
        } catch {
            defaultLogger.error("Failed to delete song: \(songName)")
            return false
        }
    }
    
}

/* Update checking */
extension AssetsDownloader {
    
    func checkUpdates(fix: Bool = false) async {
        self.fix = fix
        
        do {
            if modelData == nil {
                throw ModelError.missingModelData
            }
            if viewModel == nil {
                throw ModelError.missingViewModel
            }
            
            if fix{
                DispatchQueue.main.async{
                    self.viewModel!.assetsStatus = .checking
                }
            } else {
                DispatchQueue.main.async{
                    self.viewModel!.updateStatus = .checking
                }
            }


            try await checkSongs(checkHashes: fix)
            try await checkJackets(checkHashes: fix)
            try await checkCourses()
            
            fixesNeeded = missingSongs.count + missingJackets.count + (changedCourses ? 1 : 0)

            DispatchQueue.main.async{
                switch self.fix {
                case true:
                    switch self.fixesNeeded > 0 {
                    case true:
                        self.viewModel!.assetsStatus = .available
                        self.viewModel!.lastUpdateDate = Int(Date())
                        self.viewModel!.assetsProgressText = "0/\(self.fixesNeeded)"
                        
                    case false:
                        self.viewModel!.assetsStatus = .success
                    }
                    
                case false:
                    switch self.fixesNeeded > 0 {
                    case true:
                        self.viewModel!.updateStatus = .available
                        self.viewModel!.lastUpdateDate = Int(Date())
                        self.viewModel!.updateProgressText = "0/\(self.fixesNeeded)"

                    case false:
                        self.viewModel!.updateStatus = .success
                    }
                }
            }

        }
        catch ModelError.missingViewModel, ModelError.missingModelData {
            defaultLogger.error("Missing ViewModel or ModelData")
        }
        catch {
            defaultLogger.error("Failed to check updates")
            DispatchQueue.main.async {
                self.viewModel!.updateStatus = .fail
            }
        }
    }
    

}

/* File verification */
extension AssetsDownloader {

    private func checkSongs(checkHashes: Bool = false) async throws {
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
            if !FileManager.default.fileExists(atPath: SONG_FILE_URL(songName).path) {
//                defaultLogger.debug("Couldn't find \(SONG_FILE_URL(songName).path)")
                defaultLogger.info("adding missing song: \(songName)")
                missingSongs.append(songName)
                continue
            }
            
            // incorrect hash
            if checkHashes{
                let fileHash = try getFileHash(SONG_FILE_URL(songName))
                    .description
                    .components(separatedBy: " ")
                    .last!
                if fileHash != songHash {
                    defaultLogger.info("Hash mismatch for \(songName):")
//                    defaultLogger.debug("Hashes:\n\tlocal: \(fileHash)\n\tremote: \(songHash)")
                    missingSongs.append(songName)
                }
            }
        }
        
        // Check removed songs
        obsoleteSongs = []
        if let songFiles = FileManager.default.enumerator(at: SONGS_FOLDER_URL, includingPropertiesForKeys: nil) {
            for case let songFile as URL in songFiles {
                let songName = songFile
                    .lastPathComponent
                    .components(separatedBy: ".json")
                    .first!
                if !allSongs.contains(songName) {
                    defaultLogger.info("Obsolete song: \(songName)")
                    obsoleteSongs.append(songName)
                }
            }
        } else {
            defaultLogger.error("Failed to find \(SONGS_FOLDER_URL) when checking for obsolete songs")
        }
        
//        return (missingSongs.count + obsoleteSongs.count) > 0
    }
    
    
    
    private func checkJackets(checkHashes: Bool = false) async throws {
        // Download files
        let (allSongsURL, allSongsResponse) = try await defaultGithubDownload(GITHUB_LATEST + ALL_SONGS_FILE)
        let (hashedJacketsURL, hashedJacketsResponse) = try await defaultGithubDownload(GITHUB_LATEST + HASHED_JACKETS_FILE)
        if !responseSucceeded(allSongsResponse) || !responseSucceeded(hashedJacketsResponse){
            throw GitHubError.failedGet
        }
        let allSongs = try readLines(contentsOf: allSongsURL)
        let hashedJackets = try readLines(contentsOf: hashedJacketsURL)
        
        // Compare hashes
        missingJackets = []
        for (songName, jacketHash) in zip(allSongs, hashedJackets) {
            // missing jacket
            if !FileManager.default.fileExists(atPath: JACKET_FILE_URL(songName).path) {
//                defaultLogger.debug("Couldn't find \(JACKET_FILE_URL(songName).path)")
                defaultLogger.info("adding missing jacket: \(songName)")
                missingJackets.append(songName)
                continue
            }
            
            // incorrect hash
            if checkHashes{
                let fileHash = try getFileHash(JACKET_FILE_URL(songName))
                    .description
                    .components(separatedBy: " ")
                    .last!
                if fileHash != jacketHash {
                    defaultLogger.info("Hash mismatch for \(songName) jacket:")
    //                defaultLogger.debug("Hashes:\n\tlocal: \(fileHash)\n\tremote: \(jacketHash)")
                    missingJackets.append(songName)
                }
            }
        }
        
        // check for existing jackets
        do {
            let jacketsDir = try FileManager.default.contentsOfDirectory(at: JACKETS_FOLDER_URL, includingPropertiesForKeys: nil)
            if !jacketsDir.isEmpty {
                DispatchQueue.main.async {
                    self.viewModel!.jacketsDownloaded = true
                }
            }
        } catch{
            defaultLogger.error("Failed to list contents of \(JACKETS_FOLDER_URL)")
        }

//        return missingJackets.count > 0
    }
    
    
    private func checkCourses() async throws {
        // Download files
        let (hashedCoursesURL, hashedCoursesResponse) = try await defaultGithubDownload(GITHUB_LATEST + HASHED_COURSES_FILE)
        if !responseSucceeded(hashedCoursesResponse) {
            throw GitHubError.failedGet
        }
        
        // Compare hashes
        let hashedCourses = try readLines(contentsOf: hashedCoursesURL)
        if hashedCourses.count != 1 {
            defaultLogger.error("Downloaded \(HASHED_COURSES_FILE) has more than one hashes")
            throw FileError.fileCorrupted
        }
        
        let fileHash = try getFileHash(COURSES_FILE_URL)
            .description
            .components(separatedBy: " ")
            .last!
        
        changedCourses = fileHash != hashedCourses[0]

        if changedCourses {
            defaultLogger.info("Hash mismatch for courses:")
            defaultLogger.debug("Hashes:\n\tlocal: \(fileHash)\n\tremote: \(hashedCourses[0])")
        }
        
//        return changedCourses
    }
    
}


/* Background downloader for jackets */
extension AssetsDownloader {
    func downloadJacketsZip(){
        guard let url = URL(string: GITHUB_LATEST + JACKETS_ZIP) else { return }
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

/* Delegate for background jackets download */
extension AssetsDownloader: URLSessionDelegate, URLSessionDownloadDelegate {
    
    /* Update download progress */
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        DispatchQueue.main.async{
            self.viewModel?.downloadProgress = downloadTask.progress.fractionCompleted
            self.viewModel?.downloadProgressText = formatBytes(totalBytesWritten) + "/" + formatBytes(totalBytesExpectedToWrite)
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
 
                let savedZipURL = JACKETS_FOLDER_URL.appendingPathComponent("jackets.zip")
                try FileManager.default.moveItem(at: location, to: savedZipURL)
                
                defaultLogger.debug("Unzipping \(savedZipURL)")
                try Zip.unzipFile(savedZipURL,
                                  destination: APPDATA_FOLDER_URL,
                                  overwrite: true,
                                  password: nil,
                                  progress: nil)
                try? FileManager.default.removeItem(at: savedZipURL)

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

