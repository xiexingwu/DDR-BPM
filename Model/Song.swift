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

func getSongIndexByID(songID: String, songs: [Song]) -> Int {
    songs.firstIndex(where: {$0.id == songID })!
}

//func getSongLevelByDifficulty(song: Song, difficulty: DifficultyType) -> Int? {
//    switch difficulty {
//        case
//    }
//}

func isVariableBPMRange(bpmRange: String) -> Bool{
    return bpmRange.contains("~")
}

func getMinMaxBPM(_ bpmRange: String) -> [Int]{
    if isVariableBPMRange(bpmRange: bpmRange){
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
    
    var title: String
    var titletranslit: String
    var version: String
    var songLength: Float
    var perChart: Bool
    
    var resources: Resources
    var levels: Levels
    var chart: [Chart]
    
    
    /* Derived & constant fields */
    var jacket: Image{
        Image((resources.jacket as NSString).deletingPathExtension)
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
