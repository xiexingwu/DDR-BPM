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
    @State private var filteredSongs: [Song] = []
    @State private var randomSongs: [CourseSong] = []
    
    
    private func chooseInts(min: Int = 0, max: Int, count: Int) -> [Int] {
        var set = Set<Int>()
        while set.count < count {
            set.insert(Int.random(in: min...max))
        }
        return Array(set)
    }
    
    private func updateSongs() {
        randomSongs = []
        updateFilteredSongs()
        updateRandomSongs()
    }
    
    private func updateFilteredSongs(){
        let min = viewModel.randomMinLevel
        let max = selectLevelRange ? viewModel.randomMaxLevel : viewModel.randomMinLevel
        filteredSongs = modelData.songs.filter{
            songHasLevelBetween($0,
                                min: min,
                                max: max,
                                sd: viewModel.userSD)
        }
    }
    
    private func updateRandomSongs(_ n : Int = 4) {
        if filteredSongs.isEmpty { updateFilteredSongs() }
        let randomInts = chooseInts(max: filteredSongs.count-1, count: n)
        randomSongs = randomInts.map{filteredSongs[$0]}
            .map{ song in
                CourseSong(name: song.name, song: song, difficulty: randomDifficulty(song))
            }
    }
    
    private func randomDifficulty(_ song: Song) -> DifficultyType? {
        let levels = viewModel.userSD == .single ? song.levels.single! : song.levels.double!
        let min = viewModel.randomMinLevel
        let max = selectLevelRange ? viewModel.randomMaxLevel : viewModel.randomMinLevel

        let isBetweenMinMax : (Int?) -> Bool = { level in
            guard let level = level else { return false }
            print("level \(level) is not null")
            return level >= min && level <= max
        }
        
        var diffs : [DifficultyType] = []
        if isBetweenMinMax(levels.beginner) { diffs.append(.beginner) }
        if isBetweenMinMax(levels.easy) { diffs.append(.basic) }
        if isBetweenMinMax(levels.medium) { diffs.append(.difficult) }
        if isBetweenMinMax(levels.hard) { diffs.append(.expert) }
        if isBetweenMinMax(levels.challenge) { diffs.append(.challenge) }
        
        let randomInts = chooseInts(max: diffs.count-1, count: 1)
        return diffs[randomInts[0]]
    }
    
    var body: some View {
        let minLevelBinding = Binding(
            get: {
                viewModel.randomMinLevel
            },
            set: {
                viewModel.randomMinLevel = $0
                if viewModel.randomMaxLevel < $0 { viewModel.randomMaxLevel = $0 }
            }
        )
        let maxLevelBinding = Binding(
            get: {
                viewModel.randomMaxLevel
            },
            set: {
                viewModel.randomMaxLevel = $0
            }
        )
        
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
                .onChange(of: viewModel.randomMinLevel) { _ in updateSongs() }
                .onChange(of: viewModel.randomMaxLevel) { _ in updateSongs() }

                Button{
                    updateRandomSongs()
                }label:{
                    Label("Randomize", systemImage: "arrow.triangle.2.circlepath")
                }
                
                List{
                    
                    ForEach(randomSongs, id:\.self){ song in
                        NavigableSongRow(song: song.song!, difficulty: song.difficulty)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Random songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                /* Dropdown menu */
                ToolbarItem(placement: .navigationBarTrailing){
                    Menu{
                        /* Single/Double */
                        ToolbarMenuSD()                        
                    } label:{
                        Label("Show Menu", systemImage: "line.3.horizontal")
                    }
                }
            }
        }
        
    }
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
