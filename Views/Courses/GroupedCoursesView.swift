//
//  SongGroup.swift
//  DDR BPM
//
//  Created by Michael Xie on 24/5/2022.
//

import SwiftUI

private struct CoursesInGroup : View {
    @EnvironmentObject var modelData: ModelData
    var courseGroup: CourseGroup
    var body: some View{
        ForEach(courseGroup.courses!) {course in
            let i = getCourseIndexByID(course.id, modelData.courses)
            VStack{
                Divider()
                NavigableCourseRow(course: modelData.courses[i])
            }
        }
    }
}


/* Grouped songs view */
struct GroupedCoursesView: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
    
    var courseGroups : [CourseGroup]
    
    @State private var selectedGroup : String = ""

    var body: some View {
        if courseGroups.count > 0{
            ScrollView{
                LazyVStack(alignment:.leading, pinnedViews: [.sectionHeaders]){
                    ForEach(0 ..< courseGroups.count, id:\.self) { i in
                        let courseGroup = courseGroups[i]
                        Section(header: header(courseGroup)){
                            if selectedGroup == courseGroup.id{
                                CoursesInGroup(courseGroup: courseGroup)
                                    .padding(.vertical, 0)
                                    .padding(.horizontal)
                            }
                            Divider()
                        }
                    }
                }
                .onChange(of: courseGroups) {courseGroups in
                    if courseGroups.count == 1{
                        selectedGroup = courseGroups[0].id
                    }else {
                        selectedGroup = ""
                    }
                }
            }
        } else {
            List {
                Text("No courses matching filters.")
            }
                .listStyle(.plain)
        }
    }
    
    func header(_ courseGroup: CourseGroup) -> some View {
        var str : String = ""
        switch courseGroup.sortType{
        case .level:
            str = str + "\(courseGroup.sortType.rawValue) "
            fallthrough
        case .name:
            fallthrough
        case .version:
            fallthrough
        case .none:
            str = str + "\(courseGroup.name) : "
        }
        
        let expanded = selectedGroup == courseGroup.id
        
        return HStack(alignment:.bottom){
            Text(str)
                .foregroundColor(.primary)
                .font(.title2)
                .fontWeight(.bold)
            Text("\(courseGroup.courses!.count) courses")
                .foregroundColor(.gray)
                .font(.title3)
            Spacer()
            Image(systemName: expanded ? "chevron.down" : "chevron.right")
        }
        .padding(.horizontal)
        .frame(maxWidth:.infinity, minHeight: expanded ? 50 : 30)
        .background(.background)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedGroup = expanded ? "" : courseGroup.id
        }

    }
}
