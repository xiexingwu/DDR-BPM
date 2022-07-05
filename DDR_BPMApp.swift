//
//  DDR_BPMApp.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import SwiftUI
import OSLog

let defaultLogger = Logger()

let BUNDLE_APPDATA_FOLDER_URL = Bundle.main.url(forResource: "AppResources", withExtension: nil)!
let BUNDLE_SONGS_FOLDER_URL = BUNDLE_APPDATA_FOLDER_URL.appendingPathComponent("data")
let BUNDLE_COURSES_FILE_URL = BUNDLE_APPDATA_FOLDER_URL.appendingPathComponent("courses.json")

let DOCUMENTS_URL: URL = try! FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
let APPDATA_FOLDER_URL: URL = DOCUMENTS_URL.appendingPathComponent("AppData")
let SONGS_FOLDER_URL: URL = APPDATA_FOLDER_URL.appendingPathComponent("data")
let JACKETS_FOLDER_URL: URL = APPDATA_FOLDER_URL.appendingPathComponent("jackets")

let COURSES_FILE_URL: URL = APPDATA_FOLDER_URL.appendingPathComponent("courses.json")
let USER_COURSES_FILE_URL: URL = APPDATA_FOLDER_URL.appendingPathComponent("user_courses.json")

func SONG_FILE_URL(_ songName: String) -> URL {
    SONGS_FOLDER_URL.appendingPathComponent("\(songName).json")
}
func JACKET_FILE_URL(_ songName: String) -> URL {
    JACKETS_FOLDER_URL.appendingPathComponent("\(songName)-jacket.png")
}

@main
struct DDR_BPMApp: App {
    let favorites = Favorites()
    let viewModel = ViewModel()
    var modelData = ModelData()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(favorites)
                .environmentObject(viewModel)
                .environmentObject(modelData)
        }
    }
}
