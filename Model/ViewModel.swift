//
//  ViewModel.swift
//  DDR BPM
//
//  Created by Michael Xie on 6/5/2022.
//

import Foundation
import SwiftUI

// Convert Date to Int so AppStorage can store it
extension Int {
    init(_ date: Date) {
        self = Int(date.timeIntervalSince1970)
    }
}
extension Date {
    init(_ int: Int) {
        self = Date(timeIntervalSince1970: TimeInterval(int))
    }

    static let week: TimeInterval = TimeInterval(7 * 24 * 60 * 60)
}

class ViewModel: ObservableObject {

    /* Search util */
    @Published var searchText: String = ""
    @Published var songGroups: [SongGroup] = []
    @Published var activeSongDetail: [String] = ["", ""]  // Set this to open a Song Detail (in Song tab and in Course tab)
    @Published var activeCourseDetail: String = ""  // Set this to open a Course Detail

    /* User settings */
    @AppStorage("userReadSpeed") var userReadSpeed: Int = 600

    /* Song filters */
    @Published var markingFavorites: Bool = false
    @Published var filterFavorites: Bool = false
    @AppStorage("userDiff") var userDiff: DifficultyType = .expert
    @AppStorage("userSongSort") var userSongSort: SortType = .level
    @AppStorage("userSD") var userSD: SDType = .single
    @AppStorage("userMinLevel") var filterMinLevel: Int = 1
    @AppStorage("userMaxLevel") var filterMaxLevel: Int = 19
    @AppStorage("userRandomMin") var randomMinLevel: Int = 1
    @AppStorage("userRandomMax") var randomMaxLevel: Int = 19

    /* Course filters */
    @AppStorage("userCourseSort") var userCourseSort: SortType = .version
    @AppStorage("userShowDDRCourses") var userShowDDRCourses: Bool = true
    @AppStorage("userShowLIFE4Courses") var userShowLIFE4Courses: Bool = true
    @AppStorage("userShowCustomCourses") var userShowCustomCourses: Bool = true

    /* Updates and assets validation */
    @Published var updateStatus: UpdateStatus = .none
    @AppStorage("lastUpdateDate") var lastUpdateDate: Int = Int(
        Date(timeIntervalSinceNow: -Date.week))
    @Published var downloadProgressBytes: (Int64, Int64) = (0, 0)
}

extension ViewModel {
    func reset() {
        userReadSpeed = 600

        userDiff = .expert
        userSongSort = .level
        userSD = .single
        filterMinLevel = 1
        filterMaxLevel = 19
        randomMinLevel = 1
        randomMaxLevel = 19

        userCourseSort = .version
        userShowDDRCourses = true
        userShowLIFE4Courses = true
        userShowCustomCourses = true

        lastUpdateDate = Int(Date())
    }
}
