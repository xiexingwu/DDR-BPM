//
//  ViewModel.swift
//  DDR BPM
//
//  Created by Michael Xie on 6/5/2022.
//

import Foundation
import SwiftUI

class ViewModel : ObservableObject{
    
    /* Search util */
    @Published var searchText : String = ""
    @Published var songGroups : [SongGroup] = []
    @Published var activeSongDetail : [String] = ["", ""] // Set this to open a Song Detail (in Song tab and in Course tab)
    @Published var activeCourseDetail : String = "" // Set this to open a Course Detail

    /* User settings */
    @AppStorage("userReadSpeed") var userReadSpeed : Int = 600

    /* Song filters */
    @Published var markingFavorites : Bool = false
    @Published var filterFavorites : Bool = false
    @AppStorage("userDiff") var userDiff: DifficultyType = .expert
    @AppStorage("userSongSort") var userSongSort: SortType = .level
    @AppStorage("userSD") var userSD : SDType = .single
    @AppStorage("userMinLevel") var filterMinLevel : Int = 1
    @AppStorage("userMaxLevel") var filterMaxLevel : Int = 19

    /* Course filters */
    @AppStorage("userCourseSort") var userCourseSort: SortType = .version
    @AppStorage("userShowDDRCourses") var userShowDDRCourses : Bool = true
    @AppStorage("userShowLIFE4Courses") var userShowLIFE4Courses : Bool = true
    @AppStorage("userShowCustomCourses") var userShowCustomCourses : Bool = true

}

