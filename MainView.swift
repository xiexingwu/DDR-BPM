//
//  MainView.swift
//  DDR BPM
//
//  Created by Michael Xie on 9/5/2022.
//

import SwiftUI

extension View {
    func hideKeyboardWhenTappedAround() -> some View  {
        return self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                  to: nil, from: nil, for: nil)
        }
    }
}

struct MainView: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var modelData: ModelData

    var body: some View {
        
        let showingInitialLoadAlert = Binding(
            get: {
                modelData.initialLoad == .first
            },
            set: { _ in
                modelData.initialLoad = .done
            }
        )

        TabView {
            BPMSheet()
                .tabItem{
                    Label("BPM Wheel", systemImage: "123.rectangle")
                }
            SongView()
                .tabItem{
                    Label("Songs", systemImage : "list.dash")
                }
            CourseView()
                .tabItem{
                    Label("Courses", systemImage : "folder")
                }
            RandomView()
                .tabItem{
                    Label("Random", systemImage: "questionmark")
                }
            SettingView()
                .tabItem {
                    Label("Settings", systemImage: "gear.circle")
                }
        }
        .navigationViewStyle(.stack)
        .alert("Welcome to the DDR BPM App!\n Go to 'Settings' -> 'Check for Updates' to keep your songs up to date.", isPresented: showingInitialLoadAlert) {
            Button("OK", role: .cancel) {
                ()
            }
        }
        .onAppear{
            Task{
                let lastUpdateDate = Date(viewModel.lastUpdateDate).timeIntervalSinceNow
                defaultLogger.debug("seconds since last update: \(lastUpdateDate)")
            }
        }
    }
}

