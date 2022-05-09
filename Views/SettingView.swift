//
//  SettingView.swift
//  DDR BPM
//
//  Created by Michael Xie on 9/5/2022.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject var favorites: Favorites
    @EnvironmentObject var viewModel: ViewModel
    @State private var showingClearFavConfirmation : Bool = false
    @State private var tempReadSpeed : Int = 600
    
    @State private var alertInvalidReadSpeed : Bool = false
    @State private var alertValidReadSpeed : Bool = false
    
    private func validInput() -> Bool {
        true
    }
    
    var body: some View {
        NavigationView{
            
            List{
                
                /* Set read speed */
                HStack {
                    Text("Set read speed:")
                    
                    TextField(viewModel.userReadSpeed.formatted(),
                              value: $tempReadSpeed,
                              format: .number
                    )
                    
                    Button{
                        if validInput() {
                            alertValidReadSpeed = true
                            viewModel.userReadSpeed = tempReadSpeed
                        } else {
                            alertInvalidReadSpeed = true
                        }
                    } label: {
                        Text(" Set ")
                    }
                    .alert("Invalid read speed \(tempReadSpeed)", isPresented: $alertInvalidReadSpeed){
                        Button("OK", role: .cancel) {}
                    }
                    .alert("Read speed set to \(tempReadSpeed)", isPresented: $alertValidReadSpeed){
                        Button("OK", role: .cancel) {}
                    }
                }
                
                /* Clear favorites */
                Button(role: .destructive){
                    showingClearFavConfirmation = true
                } label:{
                    Label("Clear favorites", systemImage: "trash")
                }
                .confirmationDialog(
                    "Confirm clearing favorites?",
                    isPresented: $showingClearFavConfirmation,
                    titleVisibility: .visible
                ){
                    Button("Yes", role: .destructive){
                        favorites.clear()
                    }
                }
            }
//            .listStyle(.automatic)
            .navigationBarTitle("Settings")
        }
//        .onTapGesture {
//            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
//        }
        
    }
}

struct SettingView_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()
    static var previews: some View {
        SettingView()
            .environmentObject(modelData)
            .environmentObject(viewModel)
            .environmentObject(favorites)
    }
}
