//
//  Favorites.swift
//  DDR BPM
//
//  Created by Michael Xie on 5/5/2022.
//

import Foundation
import SwiftUI

final class Favorites: ObservableObject {
    @Published var songs: Set<String> = []
    let defaults = UserDefaults.standard
    
    init() {
//        let decoder = JSONDecoder()
//        if let data = defaults.data(forKey: "Favorites") {
//            let songData = try? decoder.decode(Set<String>.self, from: data)
//            self.songs = songData ?? []
//        } else {
//            self.songs = []
//        }
        self.songs = Set(defaults.array(forKey: "Favorites") as? [String] ?? [])
    }
    
    func getSongIds() -> Set<String> {
        return self.songs
    }
    
    func isEmpty() -> Bool {
        songs.count < 1
    }
    
    func contains(_ song: Song) -> Bool {
        songs.contains(song.id)
    }
    
    func add(_ song: Song){
        songs.insert(song.id)
        save()
    }
    
    func remove(_ song: Song){
        songs.remove(song.id)
        save()
    }
    
    func toggle(_ song: Song){
        if self.contains(song){
            self.remove(song)
        }else{
            self.add(song)
        }
    }
    
    func save() {
//        let encoder = JSONEncoder()
//        if let encoded = try? encoder.encode(songs) {
//            defaults.set(encoded, forKey: "Favorites")
//        }
        self.defaults.set(Array(self.songs), forKey: "Favorites")
    }

    func clear() {
        songs = []
        save()
    }
    
}

