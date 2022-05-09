//
//  ContentView.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import SwiftUI
extension UINavigationBar {
    static func changeAppearance(clear: Bool) {
        let appearance = UINavigationBarAppearance()
        
        if clear {
            appearance.configureWithTransparentBackground()
        } else {
            appearance.configureWithDefaultBackground()
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct ContentView: View {
    @State private var showingMenu = false
    @State private var markingFavorites = false

//    init() {
//            UINavigationBar.changeAppearance(clear: true)
//        }
    var body: some View {
        NavigableSongList()
    }
}

struct ContentView_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()
    static var previews: some View {
        ContentView()
            .environmentObject(modelData)
            .environmentObject(favorites)
            .environmentObject(viewModel)
    }
}

