//
//  DDR_BPMApp.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import SwiftUI

@main
struct DDR_BPMApp: App {
    let favorites = Favorites()
    let viewModel = ViewModel()
    var modelData = ModelData()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(favorites)
                .environmentObject(viewModel)
                .environmentObject(modelData)
        }
    }
}
