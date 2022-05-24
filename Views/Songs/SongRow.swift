//
//  SongRow.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import SwiftUI

struct DifficultiesText: View{
    @EnvironmentObject var viewModel: ViewModel
    
    var song: Song
    
    var body: some View {
        if let levels = viewModel.userSD == .single ? song.levels.single : song.levels.double {
            HStack{
                Text("\(levels.beginner?.formatted()  ?? "-")")
                    .foregroundColor(difficultyColor(.beginner))
                
                + Text(" . ") +
                
                Text("\(levels.easy?.formatted()      ?? "-")")
                    .foregroundColor(difficultyColor(.basic))
                
                + Text(" . ") +
                
                Text("\(levels.medium?.formatted()    ?? "-")")
                    .foregroundColor(difficultyColor(.difficult))
                
                + Text(" . ") +
                
                Text("\(levels.hard?.formatted()      ?? "-")")
                    .foregroundColor(difficultyColor(.expert))
                
                + Text(" . ") +
                
                Text("\(levels.challenge?.formatted() ?? "-")")
                    .foregroundColor(difficultyColor(.challenge))
                
            }
        } else {
            EmptyView()
        }
    }
}


struct SongRow: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
    
    var song: Song
    
    var isMinimal: Bool = false
    
    private var id: Int {
        modelData.songs.firstIndex(where: {$0.id == song.id })!
    }
    
    private var bpmString : String {
        let chartID = getChartIDFromUser(song, viewModel)
        let chart = song.chart[chartID]
        if isVariableBPMRange(chart.bpmRange){
            return chart.bpmRange + "~" + String(chart.dominantBpm)
        }else{
            return chart.bpmRange
        }
    }
    
    var body: some View {
        if isMinimal{
            HStack{
                Text(song.title)
                Spacer()
                Text(song.chart[0].bpmRange)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }else{
            ZStack(alignment:.topLeading){
                HStack{
                    song.jacket
                        .resizable()
                        .frame(width:50,height:50)
                    
                    VStack(alignment: .leading){
                        Text(song.title)
                        
                        HStack{
                            DifficultiesText(song:song)
                            Spacer()
                            Text(song.chart[0].bpmRange)
                            //                            Text(song.version)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                .padding(isMinimal ? 0 : 10)
                
                FavoriteButton(song: modelData.songs[id])
                    .disabled(!viewModel.markingFavorites)
                
            }
        }
    }
}


struct NavigableSongRow: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    let song : Song
    
    var body: some View{
        Button{
        } label: {
            SongRow(song: song)
        }
        .background(
            NavigationLink( destination: SongDetail(song:song) ){
                EmptyView()
            }
                .disabled(viewModel.markingFavorites)
        )
    }
}

struct SongRow_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()
    
    static var songs = modelData.songs
    static var previews: some View {
        Group{
            SongRow(song: songs[293])
            SongRow(song: songs[7], isMinimal: true)
        }
        .environmentObject(modelData)
        .environmentObject(viewModel)
        .environmentObject(favorites)
        .previewLayout(.fixed(width: 300, height: 300))
    }
}
