//
//  CourseDetail.swift
//  DDR BPM
//
//  Created by Michael Xie on 24/5/2022.
//

import SwiftUI

struct CourseDetail: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
    
    var course: Course
    
    private var songDiffs : [(Song, DifficultyType?)] {
        var songs : [(Song, DifficultyType?)] = []
        let allSongs = modelData.songs
        for song in course.songs {
            let songID = getSongIndexByName(song.name, allSongs)
            songs.append((allSongs[songID], song.difficulty))
        }
        return songs
    }
    
    private var minMaxBPM : [Int] {
        let bpms = songDiffs.map { (song, diff) -> [Int] in
            if let diff = diff{
                let chartID = getChartIDFromDifficulty(song, diff)
                return getMinMaxBPM(song.chart[chartID].bpmRange)
            }else{
                return getMinMaxBPM(song.chart[0].bpmRange)
            }
        }
        let minBPM = bpms.map {$0.first!} .min()!
        let maxBPM = bpms.map {$0.last!} .max()!
        return [minBPM, maxBPM]
    }
    
    var body: some View {
        VStack{
            Text(course.name)
                .font(.title)

            if course.level == -1{
                Text("Variable Level")
            } else {
                Text("Level \(course.level)")
            }
            
            List{
                ForEach(0 ... course.songs.count-1, id:\.self){ i in
                    let (song, diff) = songDiffs[i]
                    NavigableSongRow(song: song, difficulty: diff)
                }
            }
            .listStyle(.plain)

            BPMwheel(bpmRange: "\(minMaxBPM.first!)~\(minMaxBPM.last!)")
            
        }
    }
}


struct CourseDetail_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()
    
    static var courses = modelData.courses
    static var previews: some View {
        CourseDetail(course: courses[0])
            .environmentObject(modelData)
            .environmentObject(viewModel)
            .environmentObject(favorites)
    }
}
