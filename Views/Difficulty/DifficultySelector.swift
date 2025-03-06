//
//  DifficultySelector.swift
//  DDR BPM
//
//  Created by Michael Xie on 4/5/2022.
//

import SwiftUI

struct DifficultyButton : View {
    @EnvironmentObject var viewModel: ViewModel

    var difficulty: DifficultyType
    var level : Int?
    var text: String?
    
    var selected: Bool = false
    
    private var textColor : Color {
        difficultyColor(difficulty)
    }
    private var backgroundColor : Color {
        textColor
    }
    
    private func getActiveView() -> some View {
        Button{
            viewModel.userDiff = difficulty
        } label: {
            Text(text ?? level!.formatted())
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity)
        .background(backgroundColor.opacity(selected ? 0.4 : 0.1))
        .buttonStyle(.plain)
    }
    
    private func getInactiveView() -> some View {
        getActiveView()//.colorMultiply(.black)
    }
    
    var body : some View {
        if selected {
            getActiveView()
        }else {
            getInactiveView()
        }
    }
}

struct DifficultySelector: View {
    @EnvironmentObject var viewModel: ViewModel
    private var selectedDifficulty : DifficultyType {
        viewModel.userDiff
    }
    var song: Song?
    
    private var level : DifficultyLevels? {
        var level : DifficultyLevels?
        if let song = song {
            level = viewModel.userSD == .single ? song.sp : song.dp
        }
        return level
    }
    
    var body: some View {
        HStack{
            Group{
                if level == nil {
                    /* No input song, default difficulty text */
                    ForEach(DifficultyType.allCases, id:\.self){ difficulty in
                        DifficultyButton(difficulty: difficulty, text: difficulty.rawValue, selected: true)
//                        Text(difficulty.rawValue)
//                            .foregroundColor(difficultyColor(difficulty))
                    }
                } else {
                    DifficultyButton(difficulty: .beginner, level: level!.beginner, selected: true)
                    DifficultyButton(difficulty: .basic, level: level!.easy, selected: false)
                    DifficultyButton(difficulty: .difficult, level: level!.medium, selected: true)
                    DifficultyButton(difficulty: .expert, level: level!.hard)
                    DifficultyButton(difficulty: .challenge, level: level!.challenge)
                }
            }
            .frame(maxWidth: .infinity)
        }
                .padding()
    }
}

struct DifficultySelector_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()
    static var previews: some View {
        Group{
            DifficultySelector(song: modelData.songs[29])
            DifficultySelector()
        }
        .environmentObject(modelData)
        .environmentObject(viewModel)
        .environmentObject(favorites)
    }
}
