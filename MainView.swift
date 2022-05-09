//
//  MainView.swift
//  DDR BPM
//
//  Created by Michael Xie on 9/5/2022.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            BPMSheet()
                .tabItem{
                    Label("BPM Wheel", systemImage: "123.rectangle")
                }
            ContentView()
                .tabItem{
                    Label("Songs", systemImage : "list.dash")
                }
            SettingView()
                .tabItem {
                    Label("Settings", systemImage: "gear.circle")
                }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()

    static var previews: some View {
        MainView()
            .environmentObject(modelData)
            .environmentObject(favorites)
            .environmentObject(viewModel)
    }
}
