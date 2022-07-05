//
//  ResData.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import Foundation
import SwiftUI

protocol Sortable {
    var name: String {get}
}

enum SortType : String, Equatable, CaseIterable {
    case version = "Version"
    case level = "Level"
    case name = "Name"
    case none = "None"
}

enum SDType : String, Equatable, CaseIterable, Sortable {
    case single = "Single"
    case double = "Double"

    var name: String {
        self.rawValue
    }
    
    static prefix func ! (_ a: SDType) -> SDType {
        switch a{
        case .single:
            return .double
        case .double:
            return .single
        }
    }
}

enum VersionType : String, Equatable, CaseIterable, Sortable {
    case a3 = "DDR A3"
    case a20p = "DDR A20 PLUS"
    case a20 = "DDR A20"
    case a = "DDR A"
    case ddr14 = "DDR 2014"
    case ddr13 = "DDR 2013"
    case x3 = "DDR X3"
    case x2 = "DDR X2"
    case x = "DDR X"
    case sn2 = "DDR SuperNOVA2"
    case sn = "DDR SuperNOVA"
    case ex = "DDR EXTREME"
    case max2 = "DDR MAX2"
    case max = "DDR MAX"
    case fifth = "DDR 5th"
    case fourth = "DDR 4th"
    case third = "DDR 3rd"
    case second = "DDR 2nd"
    case first = "DDR"

    var name: String {
        self.rawValue
    }
}

func getSongIndexByID(_ songID: String, _ songs: [Song]) -> Int {
    songs.firstIndex(where: {$0.id == songID })!
}
func getSongIndexByTitletranslit(_ title: String, _ songs: [Song]) -> Int {
    songs.firstIndex(where: {
        let src = cleanTitleSearch($0.titletranslit)
        let tgt = cleanTitleSearch(title)
        return tgt == src
    })!
}
func getSongIndexByName(_ name: String, _ songs: [Song]) -> Int? {
    songs.firstIndex(where: {
        let src = cleanTitleSearch($0.name)
        let tgt = cleanTitleSearch(name)
        return tgt == src
    })
}

private func cleanTitleSearch(_ txt : String) -> String{
    txt.lowercased().filter { "0123456789abcdefghijklmnopqrstuvwxyz".contains($0) }
}


func getChartIndexFromUser(_ song: Song, _ viewModel: ViewModel) -> Int {
    let difficulty = viewModel.userDiff
    let songDifficulties : [DifficultyType] = Difficulty.fromSongSD(song, sd: viewModel.userSD).map {$0.difficulty }
    if songDifficulties.contains(difficulty){
        return getChartIndexFromDifficulty(song, viewModel.userDiff, viewModel.userSD)
    } else {
        if difficulty > songDifficulties.max()! {
            viewModel.userDiff = songDifficulties.max()!
        } else if difficulty < songDifficulties.min()! {
            viewModel.userDiff = songDifficulties.min()!
        }
        return getChartIndexFromUser(song, viewModel)
    }
}
func getChartIndexFromDifficulty(_ song: Song, _ difficulty: DifficultyType, _ sd: SDType = .single) -> Int {
    if (!song.perChart) {
        return 0
    }else{
        let songDifficulties : [DifficultyType] = Difficulty.fromSongSD(song, sd: sd).map {$0.difficulty }
            return songDifficulties.firstIndex(where: { $0 == difficulty })!
    }
}

func filterSongsByName(_ songs : [Song], _ text : String) -> [Song] {
    if text.isEmpty {return songs}
    
    let filt = songs.filter { song in
        (song.title.lowercased().contains(text.lowercased()) || song.titletranslit.lowercased().contains(text.lowercased()))
    }

    return filt
}

func hasVariableBPM(_ chart: Chart) -> Bool{
    return chart.bpms.count > 1
}

func isVariableBPMRange(_ bpmRange: String) -> Bool{
    return bpmRange.contains("~")
}

func getMinMaxBPM(_ bpmRange: String) -> [Int]{
    if isVariableBPMRange(bpmRange){
        let min = bpmRange.components(separatedBy: "~").first!
        let max = bpmRange.components(separatedBy: "~").last!
        return [Int(min)!, Int(max)!]
    }else{
        return [Int(bpmRange)!]
    }
    
}

func songHasLevel(_ song: Song, level: Int, sd: SDType = .single) -> Bool {
    if let levels = sd == .single ? song.levels.single : song.levels.double{
        return levels.beginner ?? 0 == level || levels.easy ?? 0  == level || levels.medium ?? 0  == level || levels.hard ?? 0  == level || levels.challenge ?? 0  == level
    }else{
        return false
    }
}
func songHasLevelGT(_ song: Song, level: Int=1, sd: SDType = .single) -> Bool {
    if let levels = sd == .single ? song.levels.single : song.levels.double{
        return levels.beginner ?? 0 >= level || levels.easy ?? 0  >= level || levels.medium ?? 0  >= level || levels.hard ?? 0  >= level || levels.challenge ?? 0  >= level
    }else{
        return false
    }
}
func songHasLevelLT(_ song: Song, level: Int=19, sd: SDType = .single) -> Bool {
    if let levels = sd == .single ? song.levels.single : song.levels.double{
        return levels.beginner ?? 20 <= level || levels.easy ?? 20  <= level || levels.medium ?? 20  <= level || levels.hard ?? 20  <= level || levels.challenge ?? 20  <= level
    }else{
        return false
    }
}
func songHasLevelBetween(_ song: Song, min: Int=1, max: Int=19, sd: SDType = .single) -> Bool {
    if let levels = sd == .single ? song.levels.single : song.levels.double{
        return levels.beginner  ?? 0 >= min && levels.beginner  ?? 20 <= max
        || levels.easy      ?? 0 >= min && levels.easy      ?? 20 <= max
        || levels.medium    ?? 0 >= min && levels.medium    ?? 20 <= max
        || levels.hard      ?? 0 >= min && levels.hard      ?? 20 <= max
        || levels.challenge ?? 0 >= min && levels.challenge ?? 20 <= max
    }else{
        return false
    }
}


struct SongGroup: Identifiable {//, ObservableObject {
    var sortType: SortType = .level
    var name: String = ""
    var songs: [SongGroup]? = nil


    var id: String {
        name
    }

    static func fromSong(_ song: Song, sortType: SortType) -> SongGroup {
        SongGroup(sortType: sortType, name: song.id)
    }
}

struct Song: Hashable, Codable, Identifiable {

    var name: String
    var title: String
    var titletranslit: String
    var version: String
    var songLength: Float
    var perChart: Bool
    
    var resources: Resources
    var levels: Levels
    var chart: [Chart]
    
    
    /* Derived & constant fields */
    var jacket: Image? {
        if let image = UIImage(contentsOfFile: JACKET_FILE_URL(name).path) {
            return Image(uiImage: image)
        }

        // Legacy jacket folder
        if let image = UIImage(contentsOfFile: DOCUMENTS_URL.appendingPathComponent("jackets/\(resources.jacket)").path) {
            return Image(uiImage: image)
        }
        
        return nil
    }
    
    var id: String{
        titletranslit + version
    }

}
//    enum DecodingKeys: String, CodingKey {
//        case title, titletranslit, version, songLength, perChart, resources, levels, chart
//    }
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: DecodingKeys.self)
//        title = try container.decode(String.self, forKey: .title)
//        titletranslit = try container.decode(String.self, forKey: .titletranslit)
//        version = try container.decode(String.self, forKey: .version)
//        songLength = try container.decode(Float.self, forKey: .songLength)
//        perChart = try container.decode(Bool.self, forKey: .perChart)
//        resources = try container.decode(Resources.self, forKey: .resources)
//        levels = try container.decode(Levels.self, forKey: .levels)
//        chart = try container.decode([Chart].self, forKey: .chart)
//    }

/* Nested types */
struct Resources: Hashable, Codable{
    //        var simfile: String
    var jacket: String
}

struct Levels: Hashable, Codable{
    var single: DifficultyLevels?
    var double: DifficultyLevels?
    
    struct DifficultyLevels: Hashable, Codable{
        var beginner: Int?
        var easy: Int?
        var medium: Int?
        var hard: Int?
        var challenge: Int?
    }
}

struct Chart: Hashable, Codable{
    var bpmRange: String
    var dominantBpm: Int
    var trueMin: Int
    var trueMax: Int
    var bpms: [BPM]
    var stops: [STOP]
    
    struct BPM: Hashable, Codable{
        var st: Float
        var ed: Float
        var val: Int
    }
    struct STOP: Hashable, Codable{
        var st: Float
        var dur: Float
        var beats: Float
    }
}
