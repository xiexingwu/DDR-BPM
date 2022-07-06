//
//  CourseList.swift
//  DDR BPM
//
//  Created by Michael Xie on 24/5/2022.
//

import SwiftUI

private func filterCoursesByName(_ courses : [Course], _ text : String) -> [Course] {
    if text.isEmpty {return courses}

    let filt = courses.filter { course in
        course.name.lowercased().contains(text.lowercased())
    }

    return filt
}

struct CourseList: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
    
    @Environment(\.isSearching) var isSearching

    var filteredCourses : [Course] {
        var filt = modelData.courses
        
        if !viewModel.userShowDDRCourses{
            filt = filt.filter{$0.source != "DDR"}
        }
        if !viewModel.userShowLIFE4Courses{
            filt = filt.filter{$0.source != "LIFE4"}
        }
        if !viewModel.userShowCustomCourses{
            filt = filt.filter{$0.source != "Custom"}
        }

        return filt
    }
    
    var body: some View {
        VStack{
            /* Course Grouping */
            GroupedCoursesView(courseGroups: groupCourses())

            /* Lower-screen filter */
            ToolbarCourseFilter()
        }
        .navigationTitle("Courses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            /* Dropdown menu */
            ToolbarItem(placement: .navigationBarTrailing){
                Menu{

                    /* Single/Double */
                    ToolbarMenuSD()
                    
                    /* Sort by */
                    ToolbarMenuSort(sorting: .course)
                    
                } label:{
                    ToolbarHamburger()
                }
            }
        }
        
    }
    private func groupCourses() -> [CourseGroup] {
        if !viewModel.searchText.isEmpty {
            return groupCoursesByNone(filterCoursesByName(filteredCourses, viewModel.searchText))
        }
        
        switch viewModel.userCourseSort {
        case .version:
            return groupCoursesBySource(filteredCourses)
        case .level:
            return groupCoursesByLevel(filteredCourses)
        case .name:
            fallthrough
        case .none:
            return groupCoursesByNone(filteredCourses)
        }
    }
    private func groupCoursesByNone(_ courses: [Course]) -> [CourseGroup] {
        var groups : [CourseGroup] = []
        let group = CourseGroup(
            sortType: .none,
            name: "All courses",
            courses: courses
                .map{CourseGroup.fromCourse($0, sortType: .none)}
        )
        if group.courses!.count > 0 { groups.append(group) }
        return groups
    }

    private func groupCoursesByLevel(_ courses: [Course]) -> [CourseGroup] {
        var groups : [CourseGroup] = []
        for level in (1 ... 19).reversed() {
            let group = CourseGroup(
                sortType: .level,
                name: level.formatted(),
                courses: courses
                    .filter{ $0.level == level }
                    .map{CourseGroup.fromCourse($0, sortType: .level)}
            )
            if group.courses!.count > 0 { groups.append(group) }
        }

        /* Variable level courses */
        let level = -1
        let group = CourseGroup(
            sortType: .level,
            name: "Variable",
            courses: courses
                .filter{ $0.level == level }
                .map{CourseGroup.fromCourse($0, sortType: .level)}
        )
        if group.courses!.count > 0 { groups.append(group) }

        return groups
    }
    
    private func groupCoursesBySource(_ courses: [Course]) -> [CourseGroup] {
        var groups : [CourseGroup] = []
        for source in CourseSources.allCases {
            let group = CourseGroup(
                sortType: .version,
                name: source.rawValue,
                courses: courses
                    .filter{ $0.source.lowercased() == source.rawValue.lowercased() }
                    .map{CourseGroup.fromCourse($0, sortType: .version)}
            )
            if group.courses!.count > 0 { groups.append(group) }
        }
        return groups
    }
    
}


struct NavigableCourseList: View {
//    @EnvironmentObject var modelData: ModelData
//    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View{
        NavigationView{
            CourseList()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
