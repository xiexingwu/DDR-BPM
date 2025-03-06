//
//  SongRow.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import SwiftUI
extension String{
    static let characterSet = CharacterSet(charactersIn:
       "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-=!@#$%^&*()_+,./<>?;':\"[]{}\\| "
    )
    func containsSpecialCharacter() -> Bool {
        return self.rangeOfCharacter(from: String.characterSet.inverted) != nil
    }

}

struct DifficultiesText: View{
    @EnvironmentObject var viewModel: ViewModel
    
    var song: Song
    var difficulty: DifficultyType?
    
    var body: some View {
        if let levels = viewModel.userSD == .single ? song.sp : song.dp {
            if let difficulty = difficulty {
                switch difficulty {
                case .beginner:
                    return Text("\(levels.beginner?.formatted()  ?? "-")")
                        .foregroundColor(difficultyColor(.beginner))
                case .basic:
                    return Text("\(levels.easy?.formatted()      ?? "-")")
                        .foregroundColor(difficultyColor(.basic))
                case .difficult:
                    return Text("\(levels.medium?.formatted()    ?? "-")")
                        .foregroundColor(difficultyColor(.difficult))
                case .expert:
                    return Text("\(levels.hard?.formatted()      ?? "-")")
                        .foregroundColor(difficultyColor(.expert))
                case .challenge:
                    return Text("\(levels.challenge?.formatted() ?? "-")")
                        .foregroundColor(difficultyColor(.challenge))
                }
            } else {
                var txt = Text("")
                if let level = levels.beginner {
                    txt = txt + Text(level.formatted())
                        .foregroundColor(difficultyColor(.beginner))
                    txt = txt + Text(" . ")
                }
                if let level = levels.easy {
                    txt = txt + Text(level.formatted())
                        .foregroundColor(difficultyColor(.basic))
                    txt = txt + Text(" . ")
                }
                if let level = levels.medium {
                    txt = txt + Text(level.formatted())
                        .foregroundColor(difficultyColor(.difficult))
                    txt = txt + Text(" . ")
                }
                if let level = levels.hard {
                    txt = txt + Text(level.formatted())
                        .foregroundColor(difficultyColor(.expert))
                }
                if let level = levels.challenge {
                    txt = txt + Text(levels.hard == nil ? "" : " . ")
                    txt = txt + Text(level.formatted())
                        .foregroundColor(difficultyColor(.challenge))
                }
                
                return txt
                
            }
        } else {
            return Text("")
        }
    }
}


struct SongRow: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
    
    var song: Song
    var difficulty: DifficultyType?
    var isMinimal: Bool = false
    
    private var id: Int {
        modelData.songs.firstIndex(where: {$0.id == song.id })!
    }
    
    private var bpmString : String {
        if !song.per_chart {
            return song.charts[0].bpmRange
        } else {
            let minMax = song.charts.map{ getMinMaxBPM( $0.bpmRange ) }
            let min = minMax.map{$0[0]}.min()!
            let max = minMax.map{$0.reversed()[0]}.max()!
            return min == max ? "\(min)" : "\(min)~\(max)"
        }
    }
    
    var body: some View {
        if isMinimal{
            HStack{
                if let difficulty = difficulty {
                    DifficultiesText(song:song, difficulty: difficulty)
                        .frame(minWidth: 10)
                }
                Text(song.title)
                Spacer()
                Text(bpmString)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }else{
            ZStack(alignment:.topLeading){
                HStack{
                    if let jacket = song.jacket {
                        jacket
                            .resizable()
                            .frame(width:50,height:50)
                    } else {
                        Spacer()
                            .frame(width:15)
                    }
                    
                    VStack(alignment: .leading){
                        HStack{
                            VStack{
                                Text(song.title)
                                
                                if song.jacket == nil && song.title.containsSpecialCharacter() {
                                    Text(song.titletranslit)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            
                            Text(getSongVersionAbbrev(song))
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                        }
                        
                        HStack{
                            DifficultiesText(song:song, difficulty: difficulty)
                            Spacer()
                            Text(bpmString)
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
    @EnvironmentObject var favorites : Favorites
    
    let song : Song
    var difficulty: DifficultyType?
    var courseSong : Bool = false
    var iDet : Int {
        courseSong ? 1 : 0
    }
    
    var action: ((_ song: Song, _ difficulty: DifficultyType?) -> Void)?

    var body: some View{
        let activeSongBinding = Binding(
            get: {
                viewModel.activeSongDetail[iDet] == song.id
            },
            set: {
                viewModel.activeSongDetail[iDet] = $0 ? song.id : ""
            }
        )
        
        Button{
            if let action = action {
                action(song, difficulty)
            }else{
                if viewModel.markingFavorites{
                    favorites.toggle(song)
                }
                else {
                    viewModel.activeSongDetail[iDet] = song.id
                }
            }
        } label: {
            SongRow(song: song, difficulty: difficulty)
                .contentShape(Rectangle())
        }
        .background(
            NavigationLink( destination: SongDetail(song:song, difficulty: difficulty), isActive: activeSongBinding ){
                EmptyView()
            }
                .disabled(true)
        )
        .buttonStyle(.plain)
    }
}

