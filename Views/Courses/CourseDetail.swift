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
    
    
    private var minMaxBPM : [Int] {
        let bpms = course.songs.map { courseSong -> [Int] in
            if let diff = courseSong.difficulty {
                let chartIndex = getChartIndexFromDifficulty(courseSong.song!, diff)
                return getMinMaxBPM(courseSong.song!.charts[chartIndex].bpm_range)
            }else{
                return getMinMaxBPM(courseSong.song!.charts[0].bpm_range)
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
            
            
            VStack{
                ForEach(course.songs, id:\.self){ courseSong in
                    let song = courseSong.song!

                    NavigableSongRow(song: song, difficulty: courseSong.difficulty, courseSong: true)
                }
            }

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
