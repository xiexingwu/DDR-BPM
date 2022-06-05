//
//  Menubar.swift
//  DDR BPM
//
//  Created by Michael Xie on 24/5/2022.
//

import SwiftUI


struct ToolbarMenuSort: View {
    @EnvironmentObject var viewModel: ViewModel
    
    enum Sorting {
        case song
        case course
    }
    var sorting : Sorting
    
    private var userSort : Binding<SortType> {
        switch sorting {
        case .song:
            return $viewModel.userSongSort
        case .course:
            return $viewModel.userCourseSort
        }
    }
    var body: some View {
        
        Picker(selection: userSort,
               label:Text("Sort: \(userSort.wrappedValue.rawValue)")){
            ForEach(SortType.allCases, id: \.self){ sort in
                Text(sort.rawValue)
            }
        }
               .pickerStyle(.menu)
    }
}

struct ToolbarMenuSD: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        Picker(selection: $viewModel.userSD,
               label:Text("\(viewModel.userSD.rawValue)")){
            ForEach(SDType.allCases, id: \.self){ sd in
                Text(sd.rawValue)
            }
        }
               .pickerStyle(.menu)
    }
}

struct ToolbarMenuMarkFav: View{
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        Button{
            viewModel.markingFavorites.toggle()
        } label:{
            Label("Mark favs", systemImage: viewModel.markingFavorites ? "star.fill" : "star")
        }
    }
}

struct ToolbarSongFilter: View {
    @EnvironmentObject var viewModel : ViewModel
    
    var body: some View {
        HStack{
            Label("Favs",
                  systemImage: viewModel.filterFavorites ? "star.fill" : "star")
            .onTapGesture {
                viewModel.filterFavorites.toggle()
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            
            Picker(selection: $viewModel.filterMinLevel,
                   label:Text("Min level: \(viewModel.filterMinLevel)")){
                ForEach((1...viewModel.filterMaxLevel), id:\.self){
                    Text("Min: \($0)")
                }
            }
                   .pickerStyle(.menu)
                   .frame(maxWidth: .infinity)
            
            Picker(selection: $viewModel.filterMaxLevel,
                   label:Text("Max level: \(viewModel.filterMinLevel)")){
                ForEach((viewModel.filterMinLevel...19).reversed(), id:\.self){
                    Text("Max: \($0)")
                }
            }
                   .pickerStyle(.menu)
                   .frame(maxWidth: .infinity)
            
        }
    }
}

struct ToolbarCourseFilter: View {
    @EnvironmentObject var viewModel : ViewModel
    
    var body: some View {
        HStack{
            Toggle(isOn: $viewModel.userShowDDRCourses){
                Text("DDR")
                    .frame(maxWidth:.infinity, alignment: .trailing)
            }
//            .frame(maxWidth: .infinity)

            Toggle(isOn: $viewModel.userShowLIFE4Courses){
                Text("LIFE4")
                    .frame(maxWidth:.infinity, alignment: .trailing)
            }
//            .frame(maxWidth: .infinity)

//            Toggle(isOn: $viewModel.userShowCustomCourses){
//                Text("Custom")
//                    .frame(maxWidth:.infinity, alignment: .trailing)
//            }
//            .frame(maxWidth: .infinity)

        }
    }
}
