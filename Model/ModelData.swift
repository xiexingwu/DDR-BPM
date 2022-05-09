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

    init () {
        self.songs = loadSongs("data.json").sorted(by: {
            $0.titletranslit.first! < $1.titletranslit.first!
        })
    }
    

}

func loadSongs(_ filename: String) -> [Song] {
    return load(filename)
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
