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
    
    var course: Course
    
    var body: some View {
        let activeCourseBinding = Binding(
            get: {
                viewModel.activeCourseDetail == course.id
            },
            set: {
                viewModel.activeCourseDetail = $0 ? course.id : ""
            }
        )
        VStack{
            Button{
                viewModel.activeCourseDetail = course.id
            } label: {
                header
            }
            .background(
                NavigationLink(destination: CourseDetail(course: course), isActive: activeCourseBinding){
                    EmptyView()
                }
                    .disabled(true)
            )
            .padding()
            .buttonStyle(.plain)

            ForEach(course.songs, id:\.self){ courseSong in
                SongRow(song: courseSong.song!, difficulty: courseSong.difficulty, isMinimal: true)
            }
            
        }
        
    }
    
    var header: some View {
        VStack{
            HStack{
                Text(course.name)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)

                Spacer()
                Image(systemName: "chevron.right")
            }
            
            if course.level > 0{
                Text("Level \(course.level)")
                    .font(.title3)
            }
        }
        .contentShape(Rectangle())
        .frame(maxWidth:.infinity)
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
