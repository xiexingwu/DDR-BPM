//
//  Course.swift
//  DDR BPM
//
//  Created by Michael Xie on 24/5/2022.
//

import Foundation

func getCourseIndexByID(_ courseID: String, _ courses: [Course]) -> Int {
    courses.firstIndex(where: {$0.id == courseID })!
}

enum CourseSources : String, CaseIterable {
    case DDR = "DDR"
    case LIFE4 = "LIFE4"
    case custom = "Custom"
}

struct Course: Hashable, Codable, Identifiable {
    
    var name: String
    var id: String{
        name+source
    }
    var songs: [CourseSong]
    var source: String
    
    var level: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case source
        case level
        case songs
    }
    
//    init(from decoder: Decoder, allSongs: [Song]) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        name = try values.decode(String.self, forKey: .name)
//        source = try values.decode(String.self, forKey: .source)
//        level = try values.decode(Int.self, forKey: .level)
//        songs = try values.decode([CourseSong].self, forKey: .songs)
//    }
    
    mutating func findSongs(_ allSongs: [Song]) {
        for i in 0 ... songs.count-1 {
            songs[i].findSong(allSongs)
        }
    }
}


struct CourseSong: Hashable, Codable {
    var name: String
    var song: Song?
    
    var difficulty: DifficultyType?
    
    enum CodingKeys: String, CodingKey {
        case name
        case difficulty
    }
    
    mutating func findSong(_ allSongs: [Song]){
        if let i = getSongIndexByName(name, allSongs){
            song = allSongs[i]
        }
    }
}

struct CourseGroup: Identifiable{
    
    var sortType: SortType = .name
    var name: String = ""
    var courses: [CourseGroup]?


    var id: String {
        name
    }

    static func fromCourse(_ course: Course, sortType: SortType) -> CourseGroup {
        CourseGroup(sortType: sortType, name: course.id)
    }
}
