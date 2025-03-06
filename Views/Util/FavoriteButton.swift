//
//  FavoriteButton.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import SwiftUI

struct FavoriteButton: View {
    @EnvironmentObject var favorites: Favorites
    var song: Song
    private var isFav: Bool {
        favorites.contains(song)
    }

    var body: some View {
        Button{
            if isFav{
                favorites.remove(song)
            } else {
                favorites.add(song)
            }
        } label:{
            Label("Toggle Favorite", systemImage: isFav ? "star.fill" : "star")
                .labelStyle(.iconOnly)
                .foregroundColor(isFav ? .yellow : .gray)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct FavoriteButton_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()

    static var songs = modelData.songs
    static var previews: some View {
        FavoriteButton(song: songs[239])
            .environmentObject(Favorites())
    }
}
