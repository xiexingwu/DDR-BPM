//
//  SettingView.swift
//  DDR BPM
//
//  Created by Michael Xie on 9/5/2022.
//

import SwiftUI

struct SettingView: View {
    enum FocusField: Hashable {
      case readSpeedField
    }

    @EnvironmentObject var favorites: Favorites
    @EnvironmentObject var viewModel: ViewModel
    @State private var showingClearFavConfirmation : Bool = false
    @State private var tempReadSpeed : Int?
    @FocusState private var focusedField : FocusField?

    @State private var alertInvalidReadSpeed : Bool = false
    @State private var alertValidReadSpeed : Bool = false
    
    
    private func validInput() -> Bool {
        if tempReadSpeed != nil{
            return tempReadSpeed! > 0
        } else {
            return false
        }
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
                    .focused($focusedField, equals: .readSpeedField)
                    .frame(maxWidth: .infinity)
                    
                    Button{
                        if validInput() {
                            viewModel.userReadSpeed = tempReadSpeed!
                            focusedField = nil
                            alertValidReadSpeed = true
                        } else {
                            alertInvalidReadSpeed = true
                        }
                    } label: {
                        Text(" Set ")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .alert("Invalid read speed.", isPresented: $alertInvalidReadSpeed){
                        Button("OK", role: .cancel) {
                            focusedField = .readSpeedField
                        }
                    }
                    .alert("Read speed set to \(tempReadSpeed ?? 0).", isPresented: $alertValidReadSpeed){
                        Button("OK", role: .cancel) {tempReadSpeed = nil; }
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
            .navigationBarTitle("Settings")
        }

        
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
