//
//  ResData.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import Foundation
import SwiftUI
import Combine


enum InitialLoad: String {
    case none
    case first
    case done
}

final class ModelData: ObservableObject {
    
//    @Published var initialLoad: InitialLoad = .none
    @AppStorage("initialLoad") var initialLoad: InitialLoad = .none

    var songs: [Song] = []
    var defaultCourses: [Course] = []
    var userCourses: [Course] = []
    
    var courses: [Course] {
        defaultCourses + userCourses
    }

    init () {
        initialSetup()
        
        loadData()
    }
    
    func initialSetup(forceReload: Bool = false){
        if forceReload{
            initialLoad = .none
        }

        if initialLoad == .done { return }

        do {
            // Legacy: Migrate jackets folder
            let legacyJacketsFolderURL = DOCUMENTS_URL.appendingPathComponent("jackets")
            if FileManager.default.fileExists(atPath: legacyJacketsFolderURL.path){
                defaultLogger.debug("Migrating \(legacyJacketsFolderURL.path)")
                try? FileManager.default.removeItem(at: JACKETS_FOLDER_URL)
                do {
                    try FileManager.default.moveItem(at: legacyJacketsFolderURL, to: JACKETS_FOLDER_URL)
                }
                catch {
                    defaultLogger.error("Failed to migrate legacy jackets: \(legacyJacketsFolderURL.path)")
                }
            }
            
            // Delete existing data files (but not jackets)
            if FileManager.default.fileExists(atPath: SONGS_FOLDER_URL.path) {
                do {
                    try FileManager.default.removeItem(at: SONGS_FOLDER_URL)
                }
                catch {
                    defaultLogger.error("Failed to remove \(SONGS_FOLDER_URL.path)")
                }
                
                do {
                    try FileManager.default.removeItem(at: COURSES_FILE_URL)
                }
                catch {
                    defaultLogger.error("Failed to remove \(COURSES_FILE_URL.path)")
                }
            }
            
            // copy files
            defaultLogger.debug("Copying \(BUNDLE_SONGS_FOLDER_URL.path)")
            try FileManager.default.copyItem(at: BUNDLE_SONGS_FOLDER_URL, to: SONGS_FOLDER_URL)

            defaultLogger.debug("Copying \(BUNDLE_COURSES_FILE_URL.path)")
            try FileManager.default.copyItem(at: BUNDLE_COURSES_FILE_URL, to: COURSES_FILE_URL)

            if !FileManager.default.fileExists(atPath: JACKETS_FOLDER_URL.path){
                defaultLogger.debug("Creating \(JACKETS_FOLDER_URL.path)")
                try FileManager.default.createDirectory(at: JACKETS_FOLDER_URL, withIntermediateDirectories: true)
            }

            initialLoad = .first
        }
        catch {
            defaultLogger.error("Failed initial load.")
            initialLoad = .none
        }
    }
    
    func loadData() {
        loadSongs()

        loadDefaultCourses()
        
        loadUserCourses()

        Task{
            await findDefaultCourseSongs()
            await findUserCourseSongs()
        }
    }
    
    func loadSongs() {
        var songs : [Song] = []

        guard let dataFiles = FileManager.default.enumerator(at: SONGS_FOLDER_URL, includingPropertiesForKeys: nil)
        else {
            fatalError("Failed to find \(SONGS_FOLDER_URL.path)")
        }
        
        for case let dataFile as URL in dataFiles {
            let song : Song = load(dataFile)
            songs.append(song)
        }

        self.songs = songs.sorted(by: {
            $0.titletranslit.lowercased() < $1.titletranslit.lowercased()
        })
    }

    func resetCourses() {
        userCourses = []
    }

    func loadDefaultCourses() {
        self.defaultCourses = load(COURSES_FILE_URL)
    }
    
    func loadUserCourses() {
        if FileManager.default.fileExists(atPath: USER_COURSES_FILE_URL.path){
            self.userCourses = load(USER_COURSES_FILE_URL)
        } else {
            defaultLogger.debug("No user courses found at: \(USER_COURSES_FILE_URL.path)")
        }
    }
    
    func findDefaultCourseSongs() async {
        let n = self.defaultCourses.count
        if n <= 0 { return }
        for i in 0 ..< n {
            self.defaultCourses[i].findSongs(self.songs)
        }
    }
    func findUserCourseSongs() async {
        let n = self.userCourses.count
        if n <= 0 { return }
        for i in 0 ..< n {
            self.userCourses[i].findSongs(self.songs)
        }
    }

}

extension ModelData {
    func reset() {
        initialLoad = .none
        
        do {
            // Delete legacy jacket folder
            try? FileManager.default.removeItem(at: DOCUMENTS_URL.appendingPathComponent("jackets"))
            // Delete appdata folder
            try FileManager.default.removeItem(at: APPDATA_FOLDER_URL)
        } catch {
            defaultLogger.error("Failed to delete \(APPDATA_FOLDER_URL.path) on resetting ModelData")
        }
    }
}

func load<T: Decodable>(_ file: URL) -> T {
    
    let data: Data
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(file):\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(file) as \(T.self):\n\(error)")
    }
}
