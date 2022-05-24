//
//  ResData.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import Foundation
import SwiftUI
import Combine


final class ModelData: ObservableObject {
    
    var songs: [Song] = []
    var courses: [Course] = []

    init () {
        self.songs = loadSongs("data.json").sorted(by: {
            $0.titletranslit.lowercased() < $1.titletranslit.lowercased()
        })
        self.courses = loadCourses()
    }
    
    func resetCourses() {
        self.courses = loadDefaultCourses()
    }

}

func loadSongs(_ filename: String) -> [Song] {
    return load(filename)
}
func loadDefaultCourses() -> [Course] {
    let courses : [Course] = load("courses.json")
    saveCourses(courses)
    return courses
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

func saveCourses(_ courses: [Course]) {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(courses) {
        let defaults = UserDefaults.standard
        defaults.set(encoded, forKey: "userCourses")
    }
}

func loadCourses() -> [Course] {
    let defaults = UserDefaults.standard
    if let savedCourses = defaults.object(forKey: "userCourses") as? Data {
        let decoder = JSONDecoder()
        if let loadedCourses = try? decoder.decode([Course].self, from: savedCourses) {
            return loadedCourses
        } else {
            return loadDefaultCourses()
        }
    } else {
        return loadDefaultCourses()
    }
}


