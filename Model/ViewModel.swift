//
//  ViewModel.swift
//  DDR BPM
//
//  Created by Michael Xie on 6/5/2022.
//

import Foundation
import SwiftUI

class ViewModel : ObservableObject{
    @Published var markingFavorites : Bool = false
    
    @AppStorage("userDiff") var userDiff: DifficultyType = .expert
    @AppStorage("userSort") var userSort: SortType = .level
    @AppStorage("userSD") var userSD : SDType = .single
    @AppStorage("userReadSpeed") var userReadSpeed : Int = 600

    @Published var selectedGroup : String = ""
    @Published var searchText : String = ""
    
    @Published var filterFavorites : Bool = false
    @Published var songGroups : [SongGroup] = []
    @AppStorage("userMinLevel") var filterMinLevel : Int = 1
    @AppStorage("userMaxLevel") var filterMaxLevel : Int = 19

    @Published var activeSongDetail : String = ""
}

