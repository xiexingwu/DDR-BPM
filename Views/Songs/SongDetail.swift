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

    /* TODO: Capture and apply user-selected difficulty, and consider when difficulty not available for song */

    var song: Song
    
    var id: Int {
        modelData.songs.firstIndex(where: {$0.id == song.id })!
    }

    
    private var songDifficulties : [Difficulty] {
        Difficulty.fromDifficultyLevels(song, sd: viewModel.userSD)
//        getSongDifficulties(song, sd: viewModel.userSD)
    }
    
    private var chartID: Int {
        if (!song.perChart) {
            return 0
        }else{
            return songDifficulties.firstIndex(where: { $0.difficulty == viewModel.userDiff })!
        }
    }
    
    private var chart: Chart {
        song.chart[chartID]
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

    var body: some View {
        ScrollView {

            VStack{

                HStack{
                    /* Jacket */
                    song.jacket
                        .resizable()
                        .frame(width:80, height:80)

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
                    
                    FavoriteButton(song: modelData.songs[id])
                }
                .padding([.leading, .trailing], 30)
                
                /* Version text */
                Text(song.version)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding([.bottom])
                
                /* Difficulty selector */
                VStack{
                    Text("\(viewModel.userDiff.rawValue)")

                    Picker("Pick difficulty", selection: viewModel.$userDiff){
                        ForEach(songDifficulties){ difficulty in
                            DifficultyText(difficulty:difficulty, text: difficulty.level.formatted()).tag(difficulty.difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(difficultyColor( viewModel.userDiff ))
                }

                /* BPM Wheel */
                VStack{
                    Text("BPM: \(chart.bpmRange)")

                    BPMwheel(bpmRange : song.chart[chartID].bpmRange)
                }.padding([.top, .bottom], 50)


                VStack{
                    /* BPM Changes */
                    if chart.bpms.count > 1 {
                        Divider()

                        Text("BPM")
//                        ForEach(0 ... uniqueBPMs.count - 1 , id:\.self){ i in
//                            HStack{
//                                Text(String(format: "%d", uniqueBPMs[i]))
//                                    .frame(maxWidth: .infinity)
//                                Text(String(format: "%.2f", BPMlength[i]) + "sec")
//                                    .frame(maxWidth: .infinity)
//                            }
//                        }

                        BPMPlot(song:song, chartID: chartID)
                    }

                    
                    /* Stops */
                    if chart.stops.count > 0 {
                        Divider()
                        Text("STOPS")
                        HStack{
                            Text("Start (s)")
                                .frame(maxWidth: .infinity)
                            Text("Duration (s)")
                                .frame(maxWidth: .infinity)
                            Text("Beats @\(chart.dominantBpm)")
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

            }
            
        }
    }
    
}

struct SongDetail_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()

    static var previews: some View {
        SongDetail(song: modelData.songs[29])
            .environmentObject(modelData)
            .environmentObject(viewModel)
            .environmentObject(favorites)
    }
}
