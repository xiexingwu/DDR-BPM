//
//  SongGroup.swift
//  DDR BPM
//
//  Created by Michael Xie on 6/5/2022.
//

import SwiftUI

struct GroupView : View {
    @EnvironmentObject var modelData: ModelData
    var songGroup: SongGroup
    var body: some View{
        ForEach(songGroup.songs!) {song in
            let i = getSongIndexByID(songID: song.id, songs: modelData.songs)
            let songObj = modelData.songs[i]
            NavigableSongRow(song: songObj)
        }
    }
}

struct SongGroupView : View{
    @EnvironmentObject var viewModel: ViewModel

    var songGroup: SongGroup
    @Binding var isExpanded : Bool
    
    var body: some View {
        if !viewModel.searchText.isEmpty || viewModel.userSort == .none {
            Text("\(songGroup.songs!.count) songs")
            GroupView(songGroup: songGroup)
        } else {
            DisclosureGroup (isExpanded: $isExpanded) {
                GroupView(songGroup: songGroup)
            } label:{
                header(songGroup)
            }
        }
    }
    
    func header(_ songGroup: SongGroup) -> some View {
        var view = Text("")
//        + Text("\(viewModel.selectedGroup) -- \(isExpanded ? "true" : "false")")
        switch songGroup.sortType{
        case .level:
            view = view + Text("\(songGroup.sortType.rawValue) ")
            fallthrough
        case .name:
            fallthrough
        case .version:
            fallthrough
        case .none:
            view = view + Text("\(songGroup.name)")
        }
        view = view + Text(": \(songGroup.songs!.count) songs").font(.caption).foregroundColor(.gray)
        return view
    }
    
}

/* Grouped songs view */
struct GroupedSongs: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel

    var songGroups : [SongGroup]
    
    @State private var selectedGroup : Int = -1

    var body: some View {
        if songGroups.count > 0{
            List{
                ForEach(0 ... songGroups.count - 1, id:\.self) { i in
                    let songGroup = songGroups[i]
                    SongGroupView(songGroup: songGroup, isExpanded: Binding(
                        get: { return selectedGroup == i },
                        set: { _ in return selectedGroup = selectedGroup == i ? -1 : i }
                    ))
                }
            }
            .listStyle(.plain)
        }
    }
}
