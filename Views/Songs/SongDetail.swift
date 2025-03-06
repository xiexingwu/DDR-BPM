//
//  SongDetail.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import SwiftUI



struct SongDetail: View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
   
    var song: Song
    var difficulty: DifficultyType?
    
    private var songDifficulties : [Difficulty] {
        Difficulty.fromSongSD(song, sd: viewModel.userSD)
    }
    
    private var chartIndex: Int {
        if let difficulty = difficulty {
            return getChartIndexFromDifficulty(song, difficulty, viewModel.userSD)
        } else {
            return getChartIndexFromUser(song, viewModel)
        }
    }
    
    private var chart: Chart {
        song.charts[chartIndex]
    }

    private var uniqueBPMs : [Int] {
        Array(Set(chart.bpms.map {$0.val})).sorted()
    }
    private var BPMlength: [Float] {
        var lengths : [Float] = [Float].init(repeating: 0, count: uniqueBPMs.count)
        for bpm in chart.bpms {
            lengths[uniqueBPMs.firstIndex(where: {$0 == bpm.val} )!] += bpm.ed - bpm.st
        }
        return lengths
    }
    
    private var Header: some View {
        VStack{
            
            HStack{
                /* Jacket */
                if let jacket = song.jacket{
                    jacket
                        .resizable()
                        .frame(width:80, height:80)
                }
                
                Spacer()
                
                /* Title */
                VStack{
                    Text(song.title)
                        .font(.title)
                    if (song.title != song.titletranslit){
                        Text(song.titletranslit)
                            .font(.subheadline)
                    }
                }
                
                Spacer()
            }
//            .padding([.leading, .trailing])
            
            /* Version text */
            Text(song.version)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding([.bottom])
        }
    }
    
    private var DifficultySelector: some View {
        VStack{
            
            if song.per_chart{
                let selectedDiff = Binding(
                    get: {difficulty ?? viewModel.userDiff},
                    set: {viewModel.userDiff = $0}
                )
                
                Text("\(selectedDiff.wrappedValue.rawValue)")
                
                Picker("Pick difficulty", selection: selectedDiff){
                    ForEach(songDifficulties){ difficulty in
                        DifficultyText(difficulty:difficulty, text: difficulty.level.formatted()).tag(difficulty.difficulty)
                    }
                }
                .pickerStyle(.segmented)
                .colorMultiply(difficultyColor(selectedDiff.wrappedValue))
            } else {
                DifficultiesText(song: song, difficulty: difficulty)
            }
            
        }
    }
    
    private var BPMText: some View{
        var bpmStr = chart.bpmRange
        if hasVariableBPM(chart){
            let bpms = getMinMaxBPM(bpmStr)
            if chart.true_min < bpms[0]{
                bpmStr = "(\(chart.true_min)~)" + bpmStr
            }
            if chart.true_max > bpms[bpms.count > 1 ? 1 : 0] {
                bpmStr = bpmStr + "(~\(chart.true_max))"
            }
        }
            
        return VStack{
            Text("BPM: \(bpmStr)")
            if hasVariableBPM(chart){
                Text("Mostly: \(chart.dominant_bpm)")
            }
        }
    }
    
    private var BPMPlotSection: some View {
        VStack{
            
            Divider()
            
            Text("BPM")
            
            BPMPlot(song:song, chartIndex: chartIndex)
        }
    }
    
    private var StopsSection: some View{
        VStack{
            
            Divider()
            Text("STOPS")
            HStack{
                Text("Start (s)")
                    .frame(maxWidth: .infinity)
                Text("Duration (s)")
                    .frame(maxWidth: .infinity)
                Text("Beats @\(chart.dominant_bpm)")
                    .frame(maxWidth: .infinity)
            }
            
            ForEach(chart.stops, id:\.self){ stop in
                HStack{
                    Text(String(format: "%.2f", stop.st))
                        .frame(maxWidth: .infinity)
                    Text(String(format: "%.2f", stop.dur))
                        .frame(maxWidth: .infinity)
                    Text(String(format: "%.2f", stop.beats))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    

    
    var body: some View {
        ScrollView {
            
            VStack{
                
                Header
                
                DifficultySelector
                
                /* BPM Wheel */
                VStack{
                    BPMText
                    
                    BPMwheel(bpmRange : song.charts[chartIndex].bpmRange, dominantBPM: song.charts[chartIndex].dominant_bpm)
                }.padding([.top, .bottom], 50)

                if chart.bpms.count > 1 {
                    BPMPlotSection
                }

                if chart.stops.count > 0 {
                    StopsSection
                }
                
            }
        }
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing){
                FavoriteButton(song: song)
            }
            /* Dropdown menu */
            ToolbarItem(placement: .navigationBarTrailing){
                Menu{
                    let SDCases = songHasLevelBetween(song, sd: !viewModel.userSD) ? SDType.allCases : [viewModel.userSD]
                    ToolbarMenuSD(allCases: SDCases)
                } label:{
                    ToolbarHamburger()
                }
            }
        }
    }
}

