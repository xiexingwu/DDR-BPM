//
//  SongList.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import SwiftUI

import Introspect


struct SongList: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var favorites: Favorites
    @EnvironmentObject var viewModel: ViewModel
    
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
            songHasLevelBetween(song, min: viewModel.filterMinLevel, max: viewModel.filterMaxLevel, sd: viewModel.userSD)
        }
        
        return filt
    }
    
    private func groupSongs() {
        var songGroups : [SongGroup] = []
        if !viewModel.searchText.isEmpty {
            songGroups = groupSongsByNone(filterSongsByName(filteredSongs, viewModel.searchText))
        } else {
            
            switch viewModel.userSongSort {
            case .name:
                songGroups = groupSongsByAlpha(filteredSongs)
            case .version:
                songGroups = groupSongsByVersion(filteredSongs)
            case .level:
                songGroups = groupSongsByLevel(filteredSongs)
            case .none:
                songGroups = groupSongsByNone(filteredSongs)
            }
        }
        viewModel.songGroups = songGroups
    }
    
    private func groupSongsByLevel(_ songs: [Song]) -> [SongGroup] {
        var groups : [SongGroup] = []
        for level in (viewModel.filterMinLevel ... viewModel.filterMaxLevel).reversed() {
            let group = SongGroup(
                sortType: .level,
                name: level.formatted(),
                songs: songs
                    .filter{ songHasLevel($0, level: level) }
                    .map{SongGroup.fromSong($0, sortType: .level)}
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
            name: viewModel.searchText.isEmpty ? "All songs" : "Searching \"\(viewModel.searchText)\"",
            songs: songs
                .map{SongGroup.fromSong($0, sortType: .none)}
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
                    .map{SongGroup.fromSong($0, sortType: .name)}
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
            ScrollView{
                GroupedSongsView()
            }
            .introspectScrollView{ scrollView in
                scrollView.keyboardDismissMode = .onDrag
            }
            
            /* Lower-screen filter */
            ToolbarSongFilter()
                .frame(minHeight:30)
                .onChange(of: viewModel.filterFavorites) { _ in groupSongs() }
                .onChange(of: viewModel.filterMinLevel) { _ in groupSongs() }
                .onChange(of: viewModel.filterMaxLevel) { _ in groupSongs() }
        }
        .navigationTitle("Songs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            /* Dropdown menu */
            ToolbarItem(placement: .navigationBarTrailing){
                Menu{
                    /* Mark favorites */
                    ToolbarMenuMarkFav()
                    
                    /* Single/Double */
                    ToolbarMenuSD()
                        .onChange(of: viewModel.userSD) { _ in groupSongs() }
                    
                    /* Sort by */
                    ToolbarMenuSort(sorting: .song)
                        .onChange(of: viewModel.userSongSort) { _ in groupSongs() }
                    
                } label:{
                    ToolbarHamburger()
                }
            }
        }
        .task {groupSongs()}
        .onChange(of: isSearching) { newValue in
            if !newValue {
                viewModel.searchText = ""
            }
        }
        .onChange(of: viewModel.searchText) {_ in
            groupSongs()
        }
    }
}

struct NavigableSongList: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
    
    
    var body: some View{
        NavigationView{
            SongList()
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Song name") {
        }
        .keyboardType(.alphabet)
        .disableAutocorrection(true)
        .textInputAutocapitalization(.never)

    }
}


