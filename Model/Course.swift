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

enum CourseSources : String, Equatable, CaseIterable {
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
}
struct CourseSong: Hashable, Codable {
    var name: String
    var difficulty: DifficultyType?
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
