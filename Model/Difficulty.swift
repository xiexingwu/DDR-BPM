//
//  Difficulty.swift
//  DDR BPM
//
//  Created by Michael Xie on 4/5/2022.
//

import Foundation
import SwiftUI

enum DifficultyType: String, Comparable, Equatable, CaseIterable, Codable{
    case challenge = "Challenge"
    case expert    = "Expert"
    case difficult = "Difficult"
    case basic     = "Basic"
    case beginner  = "Beginner"
    
    public static func < (_ a: DifficultyType, _ b: DifficultyType) -> Bool {
        return Int(a) < Int(b)
    }
    private static func Int (_ a: DifficultyType) -> Int {
        switch a{
        case .challenge:
            return 4
        case .expert:
            return 3
        case .difficult:
            return 2
        case .basic:
            return 1
        case .beginner:
            return 0
        }
    }
}

func getSongDifficulties(_ song: Song, sd: SDType = .single) -> [Difficulty]{
    var arr : [Difficulty] = []
    
    if let levels = sd == .single ? song.sp : song.dp{
        if let level = levels.beginner {
            arr.append(Difficulty(difficulty:.beginner, level:level))
        }
        if let level = levels.easy{
            arr.append(Difficulty(difficulty:.basic, level:level))
        }
        if let level = levels.medium{
            arr.append(Difficulty(difficulty:.difficult, level:level))
        }
        if let level = levels.hard{
            arr.append(Difficulty(difficulty:.expert, level:level))
        }
        if let level = levels.challenge{
            arr.append(Difficulty(difficulty:.challenge, level:level))
        }
    }

    return arr
}

func difficultyColor (_ difficulty: DifficultyType) -> Color {

    switch difficulty {
    case .beginner:
//        return .cyan
        return Color(hexString: "#0095C4")
    case .basic:
        return Color(hexString: "#C47E01")
    case .difficult:
        return Color(hexString: "#C41C26")
    case .expert:
        return Color(hexString: "#33B628")
    case .challenge:
        return Color(hexString: "#EC38FF")
    }
}

struct Difficulty: Hashable, Identifiable {
    var difficulty: DifficultyType
    var level: Int
    var id: DifficultyType {
        difficulty
    }
    
    static func fromSongSD(_ song: Song, sd: SDType) -> [Difficulty] {
        var arr : [Difficulty] = []
        if let difficultyLevels = sd == .single ? song.sp : song.dp {
            if let l = difficultyLevels.beginner  {
                arr.append(Difficulty(
                    difficulty: .beginner,
                    level: l))
            }
            if let l = difficultyLevels.easy      {
                arr.append(Difficulty(
                    difficulty: .basic,
                    level: l))
            }
            if let l = difficultyLevels.medium    {
                arr.append(Difficulty(
                    difficulty: .difficult,
                    level: l))
            }
            if let l = difficultyLevels.hard      {
                arr.append(Difficulty(
                    difficulty: .expert,
                    level: l))
            }
            if let l = difficultyLevels.challenge {
                arr.append(Difficulty(
                    difficulty: .challenge,
                    level: l))
            }
        }
        return arr
    }
}

extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
