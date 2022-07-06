//
//  SongGroup.swift
//  DDR BPM
//
//  Created by Michael Xie on 6/5/2022.
//

import SwiftUI

private struct SongsInGroup : View {
    @EnvironmentObject var modelData: ModelData
    var songGroup: SongGroup
    var body: some View{
        ForEach(songGroup.songs!) {song in
            let i = getSongIndexByID(song.id, modelData.songs)
            let songObj = modelData.songs[i]
            VStack{
                Divider()
                NavigableSongRow(song: songObj)
            }
        }
    }
}

/* Grouped songs view */
struct GroupedSongsView: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var selectedGroup : String = ""
    
    var body: some View {
        let songGroups = viewModel.songGroups
        if songGroups.count > 0{
            ScrollView{
                LazyVStack(alignment:.leading, pinnedViews: [.sectionHeaders]){
                    ForEach(0 ..< songGroups.count, id:\.self) { i in
                        let songGroup = songGroups[i]
                        Section(header: header(songGroup)){
                            if selectedGroup == songGroup.id{
                                SongsInGroup(songGroup: songGroup)
                                    .padding(.vertical, 0)
                                    .padding(.horizontal)
                            }
                            Divider()
                        }
                    }
                }
            }
            .onChange(of: viewModel.songGroups) {songGroups in
                if songGroups.count == 1{
                    selectedGroup = songGroups[0].id
                } else {
                    selectedGroup = ""
                }
            }
        } else {
            List{
                Text("No songs matching filters.")
            }
                .listStyle(.plain)
        }
    }
    
    func header(_ songGroup: SongGroup) -> some View {
        var str : String = ""
        switch songGroup.sortType{
        case .level:
            str = str + "\(songGroup.sortType.rawValue) "
            fallthrough
        case .name:
            fallthrough
        case .version:
            fallthrough
        case .none:
            str = str + "\(songGroup.name) : "
        }
        
        let expanded = selectedGroup == songGroup.id
        
        return HStack(alignment:.bottom){
            Text(str)
                .foregroundColor(.primary)
                .font(.title2)
                .fontWeight(.bold)
            Text("\(songGroup.songs!.count) songs")
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
            selectedGroup = expanded ? "" : songGroup.id
        }
    }
}


