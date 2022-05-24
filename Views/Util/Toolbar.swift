//
//  Menubar.swift
//  DDR BPM
//
//  Created by Michael Xie on 24/5/2022.
//

import SwiftUI

struct Toolbar: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ToolbarMenuSort: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        Picker(selection: $viewModel.userSort,
               label:Text("Sort: \(viewModel.userSort.rawValue)")){
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
