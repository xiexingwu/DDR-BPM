//
//  DifficultyText.swift
//  DDR BPM
//
//  Created by Michael Xie on 4/5/2022.
//

import SwiftUI

struct DifficultyText: View {
    var difficulty : Difficulty
    var text: String?

    private var textColor: Color{
        difficultyColor(difficulty.difficulty)
    }

    var body: some View {
        Text(text ?? difficulty.level.formatted())
            .foregroundColor(textColor)
            .padding()
            .frame(maxWidth: .infinity)
    }
}


struct DifficultyText_Previews: PreviewProvider {
    static let b5 = Difficulty(difficulty: .beginner, level: 5)
    static let c19 = Difficulty(difficulty: .challenge, level: 19)
    static var previews: some View {
        Group{
            DifficultyText(difficulty:b5 )
            DifficultyText(difficulty:c19, text:"some text")
        }
        .previewLayout(.fixed(width: 300, height: 300))

    }
}

