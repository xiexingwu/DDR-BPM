//
//  SongList.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import SwiftUI

//prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
//    Binding<Bool>(
//        get: { !value.wrappedValue },
//        set: { value.wrappedValue = !$0 }
//    )
//}

private func filterSongsByName(_ songs : [Song], _ text : String) -> [Song] {
    if text.isEmpty {return songs}

    let filt = songs.filter { song in
        (song.title.lowercased().contains(text.lowercased()) || song.titletranslit.lowercased().contains(text.lowercased()))
    }
    print("---------")
    for song in filt {
        print(song.title)
    }
    return filt
}

struct SongList: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var favorites: Favorites
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var showingBPMsheet : Bool = true
    @Environment(\.isSearching) var isSearching

    var filteredSongs : [Song] {
        var filt = modelData.songs
        
        /* Filter favorites */
        if viewModel.filterFavorites {
            filt = filt.filter { song in
                favorites.contains(song)
            }
        }
        
        /* Filter levels */
        filt = filt.filter { song in
            songHasLevelBetween(song, min: viewModel.filterMinLevel, max: viewModel.filterMaxLevel)
        }
        
        return filt
    }
    
    private func groupSongs() -> [SongGroup] {
        if !viewModel.searchText.isEmpty {
            return groupSongsByNone(filterSongsByName(filteredSongs, viewModel.searchText))
        }
        
        switch viewModel.userSort {
        case .name:
            return groupSongsByAlpha(filteredSongs)
        case .version:
            return groupSongsByVersion(filteredSongs)
        case .level:
            return groupSongsByLevel(filteredSongs)
        case .none:
            return groupSongsByNone(filteredSongs)
        }
    }
    
    private func groupSongsByLevel(_ songs: [Song]) -> [SongGroup] {
        var groups : [SongGroup] = []
        for level in (1 ... 19).reversed() {
            let group = SongGroup(
                sortType: .level,
                name: level.formatted(),
                songs: songs
                    .filter{ songHasLevel($0, level: level) }
                    .map{SongGroup.fromSong($0, sortType: .version)}
            )
            if group.songs!.count > 0 { groups.append(group) }
        }
        return groups
    }
    
    private func groupSongsByVersion(_ songs: [Song]) -> [SongGroup] {
        var groups : [SongGroup] = []
        for version in VersionType.allCases {
            let group = SongGroup(
                sortType: .version,
                name: version.rawValue,
                songs: songs
                    .filter{$0.version == version.rawValue}
                    .map{
                        return SongGroup.fromSong($0, sortType: .version)}
            )
            if group.songs!.count > 0 { groups.append(group) }
        }
        return groups
    }
    
    private func groupSongsByNone(_ songs: [Song]) -> [SongGroup] {
        var groups : [SongGroup] = []
        let group = SongGroup(
            sortType: .none,
            name: "All songs",
            songs: songs
                .map{SongGroup.fromSong($0, sortType: .version)}
        )
        if group.songs!.count > 0 { groups.append(group) }
        return groups
    }
    
    private func groupSongsByAlpha(_ songs: [Song]) -> [SongGroup] {
        var groups : [SongGroup] = []
        for char in self.alphaSortOrder {
            let group = SongGroup(
                sortType: .name,
                name: String(char),
                songs: songs
                    .filter{$0.titletranslit.first! == char}
                    .map{SongGroup.fromSong($0, sortType: .version)}
            )
            if group.songs!.count > 0 { groups.append(group) }
        }
        return groups
    }
    
    private var alphaSortOrder : [String.Element] {
        Set(modelData.songs.map{$0.titletranslit.first!})
            .map{ $0 }.sorted()
    }
    
    
    var body: some View {
        VStack{
            
            /* Song Grouping */
            GroupedSongs(songGroups: groupSongs())
            
            /* Lower-screen filter */
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
            
            Text("Filters")
        }
        .navigationBarTitle("Songs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            /* Dropdown menu */
            ToolbarItem(placement: .navigationBarTrailing){
                Menu{
                    /* Mark favorites */
                    Button{
                        viewModel.markingFavorites.toggle()
                    } label:{
                        Label("Mark favs", systemImage: viewModel.markingFavorites ? "star.fill" : "star")
                    }
                    
                    /* Single/Double */
                    Picker(selection: $viewModel.userSD,
                           label:Text("\(viewModel.userSD.rawValue)")){
                        ForEach(SDType.allCases, id: \.self){ sd in
                            Text(sd.rawValue)
                        }
                    }
                           .pickerStyle(.menu)
                    
                    /* Sort by */
                    Picker(selection: $viewModel.userSort,
                           label:Text("Sort: \(viewModel.userSort.rawValue)")){
                        ForEach(SortType.allCases, id: \.self){ sort in
                            Text(sort.rawValue)
                        }
                    }
                           .pickerStyle(.menu)
                    
                    
                } label:{
                    Label("Show Menu", systemImage: "line.3.horizontal")
//                        .padding(15)
                }
            }
            
        }
        .onChange(of: isSearching) { newValue in
            if !newValue {
                viewModel.searchText = ""
            }
        }
    }
}

struct NavigableSongList: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel

    @Environment(\.dismissSearch) var dismissSearch
    @State private var searchText : String = ""
    
    var body: some View{
        NavigationView{
            SongList()
        }
//        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always)) {
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always)) {
            ForEach(filterSongsByName(modelData.songs, searchText)) { song in
                Text(song.title)
                    .searchCompletion(song.titletranslit.lowercased())
                    .searchCompletion(song.title.lowercased())
            }
        }
        .keyboardType(.default)
        .disableAutocorrection(true)
        .textInputAutocapitalization(.never)
        .onSubmit(of: .search){
            viewModel.searchText = searchText
            dismissSearch()
        }

    }
}



struct SongList_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()
    
    static var previews: some View {
        NavigableSongList()
        //        .ignoresSafeArea()
            .environmentObject(modelData)
            .environmentObject(viewModel)
            .environmentObject(favorites)
            .preferredColorScheme(.dark)
    }
}
