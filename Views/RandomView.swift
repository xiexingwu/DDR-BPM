//
//  RandomView.swift
//  DDR BPM
//
//  Created by Michael Xie on 29/5/2022.
//

import SwiftUI

struct SingleLevelPicker: View{
    @EnvironmentObject var viewModel : ViewModel
    @Binding var minLevel : Int
    
    var body: some View{
        HStack{
            Text("Level ")
            Picker(selection: $minLevel){
                ForEach((1 ... 19).reversed(), id: \.self){ level in
                    Text("\(level)")
                }
            }label:{}
        }
    }
}
struct RangedLevelPicker: View{
    @Binding var minLevel : Int
    @Binding var maxLevel : Int
    
    var body: some View{
        HStack{
            Text("Level ")
            Picker(selection: $minLevel){
                ForEach((1 ... maxLevel).reversed(), id: \.self){ level in
                    Text("\(level)")
                }
            }label:{}
            Text(" to ")
            Picker(selection: $maxLevel){
                ForEach((minLevel ... 19).reversed(), id: \.self){ level in
                    Text("\(level)")
                }
            }label:{}
        }
    }
}
struct RandomView: View {
    @EnvironmentObject var viewModel : ViewModel
    @EnvironmentObject var modelData : ModelData
    
    @State private var selectLevelRange: Bool = false
    @State private var minLevel: Int?
    @State private var maxLevel: Int?
    
    @ObservedObject var randomSongViewModel : RandomSongViewModel = RandomSongViewModel()
    
    private func chooseInts(min: Int = 0, max: Int, count: Int) -> [Int] {
        var set = Set<Int>()
        while set.count < count {
            set.insert(Int.random(in: min...max))
        }
        return Array(set)
    }
    
    private func updateRandomSongs(_ songs: [Song], _ n : Int = 4) {
        let randomInts = chooseInts(max: songs.count-1, count: n)
        randomSongViewModel.songs = randomInts.map{songs[$0]}
    }
    
    var body: some View {
        let minLevelBinding = Binding(
            get: {
                minLevel ?? viewModel.filterMinLevel
            },
            set: {
                minLevel = $0
            }
        )
        let maxLevelBinding = Binding(
            get: {
                maxLevel ?? viewModel.filterMaxLevel
            },
            set: {
                maxLevel = $0
            }
        )
        let filteredSongs : [Song] = modelData.songs.filter{
            songHasLevelBetween($0,
                                min: minLevelBinding.wrappedValue,
                                max: selectLevelRange ? maxLevelBinding.wrappedValue : minLevelBinding.wrappedValue,
                                sd: viewModel.userSD)
        }
        
        
        NavigationView{
            
            VStack {
                HStack{
                    if selectLevelRange{
                        RangedLevelPicker(minLevel: minLevelBinding, maxLevel: maxLevelBinding)
                    } else {
                        SingleLevelPicker(minLevel: minLevelBinding)
                    }
                    
                    Spacer()
                    
                    Toggle(isOn: $selectLevelRange){
                        Text("Range?")
                            .frame(maxWidth:.infinity, alignment: .trailing)
                    }
                }
                .padding()
                
                Button{
                    updateRandomSongs(filteredSongs)
                }label:{
                    Label("Randomize", systemImage: "arrow.triangle.2.circlepath")
                }
                
                List{
                    
                    ForEach(randomSongViewModel.songs, id:\.self){ song in
                        NavigableSongRow(song: song)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Random songs")
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
}

class RandomSongViewModel : ObservableObject {
    @Published var songs : [Song] = []
}

struct RandomView_Previews: PreviewProvider {
    static let viewModel = ViewModel()
    static let modelData = ModelData()
    static let favorites = Favorites()
    static var previews: some View {
        RandomView()
            .environmentObject(modelData)
            .environmentObject(viewModel)
            .environmentObject(favorites)
    }
}
