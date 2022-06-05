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
            NavigableCourseRow(course: modelData.courses[i])
        }
    }
}

private struct GroupedCourses : View{
    @EnvironmentObject var viewModel: ViewModel
    
    var courseGroup: CourseGroup
    @Binding var isExpanded : Bool
    
    var body: some View {
        if !viewModel.searchText.isEmpty || viewModel.userCourseSort == .none {
//            Text("\(courseGroup.courses!.count) courses")
            CoursesInGroup(courseGroup: courseGroup)
        } else {
            DisclosureGroup (isExpanded: $isExpanded) {
                CoursesInGroup(courseGroup: courseGroup)
            } label:{
                header(courseGroup)
            }
        }
    }
    
    func header(_ courseGroup: CourseGroup) -> some View {
        var view = Text("")
        switch courseGroup.sortType{
        case .level:
            if courseGroup.name != "Variable"{
                view = view + Text(courseGroup.sortType.rawValue+" ")
            }
            fallthrough
        case .name:
            fallthrough
        case .version:
            fallthrough
        case .none:
            view = view + Text("\(courseGroup.name)")
        }
        view = view + Text(": \(courseGroup.courses!.count) courses").font(.caption).foregroundColor(.gray)
        return view
    }
    
}

/* Grouped songs view */
struct GroupedCourseView: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
    
    var courseGroups : [CourseGroup]
    
    @State private var selectedGroup : Int = -1
    
    var body: some View {
        if courseGroups.count > 0{
            List{
                ForEach(0 ... courseGroups.count - 1, id:\.self) { i in
                    let courseGroup = courseGroups[i]
                    GroupedCourses(courseGroup: courseGroup, isExpanded: Binding(
                        get: { return selectedGroup == i },
                        set: { _ in return selectedGroup = selectedGroup == i ? -1 : i }
                    ))
                }
            }
            .listStyle(.plain)
        } else {
            List {
                EmptyView()
            }
            .listStyle(.plain)
        }
    }
}
