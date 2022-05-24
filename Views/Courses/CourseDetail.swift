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
    
    private var songs : [Song] {
        var songs : [Song] = []
        let allSongs = modelData.songs
        for title in course.titles {
            let songID = getSongIndexByTitletranslit(title, allSongs)
            songs.append(allSongs[songID])
        }
        return songs
    }
    
    private var minMaxBPM : [Int] {
        let bpms = songs.map {getMinMaxBPM($0.chart[0].bpmRange)}
        let minBPM = bpms.map {$0.first!} .min()!
        let maxBPM = bpms.map {$0.last!} .max()!
        return [minBPM, maxBPM]
    }
    
    var body: some View {
        VStack{
            Text(course.name)
                .font(.title)

            List{
                ForEach(songs, id:\.self){ song in
                    NavigableSongRow(song: song)
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
