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
    
    private var songs : [Song] {
        var songs : [Song] = []
        let allSongs = modelData.songs
        for title in course.titles {
            let songID = getSongIndexByTitletranslit(title, allSongs)
            songs.append(allSongs[songID])
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


            ForEach(songs, id:\.self){ song in
                SongRow(song: song, isMinimal: true)
            }

        }

    }
    
    var header: some View {
        Text(course.name)
            .font(.title2)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
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
