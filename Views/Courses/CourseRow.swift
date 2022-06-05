//
//  CourseRow.swift
//  DDR BPM
//
//  Created by Michael Xie on 24/5/2022.
//

import SwiftUI

struct NavigableCourseRow: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
    
    @State var isExpanded : Bool = false

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
    
    var body: some View {
        VStack{
            Button{
            } label: {
                header
            }
            .background(
                NavigationLink(destination: CourseDetail(course: course) ){
                    EmptyView()
                }
            )
            .padding()

            ForEach(0 ... course.songs.count-1, id:\.self){ i in
                let (song, diff) = songDiffs[i]
                SongRow(song: song, difficulty: diff, isMinimal: true)
            }

        }

    }
    
    var header: some View {
        VStack{
            Text(course.name)
                .font(.title2)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)

            if course.level > 0{
                Text("Level \(course.level)")
                    .font(.title3)
            }
        }
    }
}

struct CourseRow_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()

    static var courses = modelData.courses
    static var previews: some View {
        NavigableCourseRow(course: courses[0])
            .environmentObject(modelData)
            .environmentObject(viewModel)
            .environmentObject(favorites)
    }
}
