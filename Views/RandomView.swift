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

struct BPMPicker: View{
    @Binding var bpm: BPMRange

    var body: some View {
        HStack{
            
            Text("BPM ")
            Picker(selection: $bpm){
                ForEach(BPMRange.allCases, id: \.self){ bpm in
                    Text("\(bpm.description)")
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
    
    @State private var selectedBPMRange: BPMRange = .any
    @State private var allowBPMMultiple: Bool = false
    @State private var showingBPMInfo: Bool = false
    
    
    private func updateSongs() {
        randomSongs = []
        updateFilteredSongs()
        updateRandomSongs()
    }
    
    private func updateFilteredSongs(){
        let minLevel = viewModel.randomMinLevel
        let maxLevel = selectLevelRange ? viewModel.randomMaxLevel : viewModel.randomMinLevel

        filteredSongs = modelData.songs.filter{
            songHasLevelBetween($0,
                                min: minLevel,
                                max: maxLevel,
                                sd: viewModel.userSD)
        }

        if selectedBPMRange != .any {
            filteredSongs = filteredSongs.filter{
                songHasBPM($0,
                           bpmRange: selectedBPMRange,
                           allowMultiple: allowBPMMultiple,
                           minLevel: minLevel,
                           maxLevel: maxLevel,
                           sd: viewModel.userSD)
            }
        }
        
        if filteredSongs.isEmpty {
            defaultLogger.error("No songs match random filter.")
        }

    }
    
    private func updateRandomSongs(_ n : Int = 4) {
        if filteredSongs.isEmpty { updateFilteredSongs() }
        if filteredSongs.isEmpty { return }
        
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
            return level >= min && level <= max
        }
        
        var diffs : [DifficultyType] = []
        if isBetweenMinMax(levels.beginner) { diffs.append(.beginner) }
        if isBetweenMinMax(levels.easy) { diffs.append(.basic) }
        if isBetweenMinMax(levels.medium) { diffs.append(.difficult) }
        if isBetweenMinMax(levels.hard) { diffs.append(.expert) }
        if isBetweenMinMax(levels.challenge) { diffs.append(.challenge) }
        
        switch diffs.count{
        case 0:
            defaultLogger.error("randomDifficulty returned nil.\n\(song.name) with level range: \(min)~\(max)")
            return nil
        case 1:
            return diffs[0]
        default:
            let randomInts = chooseInts(max: diffs.count-1, count: 1)
            return diffs[randomInts[0]]
        }
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
                // Level Picker
                HStack{
                    if selectLevelRange{
                        RangedLevelPicker(minLevel: minLevelBinding, maxLevel: maxLevelBinding)
                    } else {
                        SingleLevelPicker(minLevel: minLevelBinding)
                    }
                    
                    Spacer()
                    
                    Toggle(isOn: $selectLevelRange){
                        Text("Range")
                            .frame(maxWidth:.infinity, alignment: .trailing)
                    }
                }
                .padding()
                .onChange(of: viewModel.randomMinLevel) { _ in updateSongs() }
                .onChange(of: viewModel.randomMaxLevel) { _ in updateSongs() }

                // BPM Picker
                HStack{
                    BPMPicker(bpm: $selectedBPMRange)

                    Spacer()
                    
                    Toggle(isOn: $allowBPMMultiple) {
                        HStack{
                            // Info button for multiples
                            Button{
                                showingBPMInfo = true
                            } label: {
                                Label("Multiple of BPM info", systemImage: "info.circle.fill")
                                    .labelStyle(.iconOnly)
                            }
                            .alwaysPopover(isPresented: $showingBPMInfo){
                                Text("Allow 0.5x, 2x this BPM.")
//                                Text("Selecting this option also includes songs with integer multiples of the selected BPM.\nExample: selecting 110 BPM songs will also show 220 and 440 songs.")
                                    .padding()
                            }
                            .buttonStyle(.plain)

                            Text("Allow multiples")
                        }
                            .frame(maxWidth:.infinity, alignment: .trailing)
                    }
                    .onChange(of: allowBPMMultiple) {_ in updateSongs()}
                    .onChange(of: selectedBPMRange) {_ in updateSongs()}

                }
                .padding()

                
                // Refresh
                Button{
                    updateRandomSongs()
                }label:{
                    Label("Randomize", systemImage: "arrow.triangle.2.circlepath")
                }
                
                
                // Results
                List{
                    
                    ForEach(randomSongs, id:\.self){ song in
                        NavigableSongRow(song: song.song!, difficulty: song.difficulty)
                    }
                    
                    if randomSongs.isEmpty{
                        Text("No songs match filters.")
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


private func chooseInts(min: Int = 0, max: Int, count: Int) -> [Int] {
//    defaultLogger.debug("choose \(count) from \(min)...\(max)")
        
    var set = Set<Int>()
    let roll : () -> Bool = {
        if set.count == count { return false }
        
        let choices = max - min + 1
        if choices < count && set.count >= choices {
            return false
        }
        return true
    }

    while roll(){
        set.insert(Int.random(in: min...max))
    }
//    defaultLogger.debug("set is \(set)")
    return Array(set)
}
