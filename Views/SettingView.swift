//
//  SettingView.swift
//  DDR BPM
//
//  Created by Michael Xie on 9/5/2022.
//

import SwiftUI

enum FocusField: Hashable {
    case readSpeedField
}
enum ShowingConfirmation: Hashable{
    case none
    case clearFavs
    case clearCourses
    case clearAssets
    case downloadAssets
}

struct SettingView: View {
    
    @State private var showingConfirmation: ShowingConfirmation = .none
    @FocusState private var focusedField : FocusField?
    
    
    var body: some View { NavigationView{
        VStack{
            List{
                ReadSpeedInput(focusedField: _focusedField)
                
                AssetsButton(showing: $showingConfirmation)
                
                ClearFavsButton(showing: $showingConfirmation)
                
                //                    ClearCoursesButton(showing: $showingConfirmation)
            }
            .navigationBarTitle("Settings")
            
            Link("Support me (PayPal)", destination: URL(string: "https://www.paypal.com/donate/?hosted_button_id=2R64RY6ZL52EW")!)
            //                    .foregroundColor(.blue)
        }
    }}
}


struct ReadSpeedInput : View {
    @EnvironmentObject var viewModel: ViewModel
    //    var focusedField: FocusState<FocusField?>.Binding
    @FocusState var focusedField: FocusField?
    
    @State private var tempReadSpeed : Int?
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
    }
    
}

struct ClearFavsButton : View {
    @EnvironmentObject var favorites: Favorites
    @Binding var showing: ShowingConfirmation
    
    var body: some View {
        let showingBool = Binding(get: {showing == .clearFavs}, set: {showing = $0 ? .clearFavs : .none})
        Button(role: .destructive){
            showing = .clearFavs
        } label:{
            Label("Clear favorites", systemImage: "trash")
        }
        .confirmationDialog(
            "Confirm clearing favorites?",
            isPresented: showingBool,
            titleVisibility: .visible
        ){
            Button("Yes", role: .destructive){
                favorites.clear()
            }
        }
    }
}


struct ClearCoursesButton : View {
    @EnvironmentObject var modelData: ModelData
    @Binding var showing: ShowingConfirmation
    
    var body: some View {
        let showingBool = Binding(get: {showing == .clearCourses}, set: {showing = $0 ? .clearFavs : .none})
        
        Button(role: .destructive){
            showing = .clearCourses
        } label:{
            Label("Reset courses", systemImage: "trash")
        }
        .confirmationDialog(
            "Confirm resetting courses?",
            isPresented: showingBool,
            titleVisibility: .visible
        ){
            Button("Yes", role: .destructive){
                modelData.resetCourses()
            }
        }
    }
}

struct AssetsButton : View {
    @EnvironmentObject var viewModel: ViewModel
    @Binding var showing: ShowingConfirmation
    @StateObject var downloader = AssetsDownloader()

    var body: some View {
//        let failBinding = Binding(
//            get:{ viewModel.downloadStatus == .fail },
//            set:{ viewModel.downloadStatus = $0 ? .fail : .none}
//        )
//        let successBinding = Binding(
//            get:{ viewModel.downloadStatus == .success },
//            set:{ viewModel.downloadStatus = $0 ? .success : .none}
//        )
        
        if viewModel.jacketsDownloaded{
            ClearAssetsButton
        } else {
            DownloadAssetsButton
//                .alert("Download failed.", isPresented: failBinding){
//                    Button("OK", role: .cancel) {}
//                }
//                .alert("Download Finished.", isPresented: successBinding){
//                    Button("OK", role: .cancel) {}
//                }
        }
    }
    
    var DownloadAssetsButton : some View {
        let showingBool = Binding(get: {showing == .downloadAssets}, set: {showing = $0 ? .downloadAssets : .none})
        return Button{
            showing = .downloadAssets
        } label: {
            HStack{
                Label("Download CD jackets", systemImage: "square.and.arrow.down")

                if viewModel.downloadProgress >= 0 && viewModel.downloadProgress < 1{
                    Spacer()
                    let str = viewModel.downloadProgressText + String(format:" (%.0f%%)", viewModel.downloadProgress * 100)
                    Text(str)
                        .font(.caption)
                } else if viewModel.downloadProgress >= 1 {
                    Spacer()
                    Text("Processing")
                }
            }
        }
        .confirmationDialog(
            "Download CD jackets (Approx \(ASSETS_SIZE)?",
            isPresented: showingBool,
            titleVisibility: .visible
        ){
            Button("Yes", role: .destructive){
                downloader.linkViewModel(viewModel: viewModel)
                downloader.downloadJacketsZip()
            }
        }
    }
    
    var ClearAssetsButton : some View {
        let showingBool = Binding(get: {showing == .clearAssets}, set: {showing = $0 ? .clearAssets : .none})
        return Button(role: .destructive){
            showing = .clearAssets
        } label: {
            Label("Clear Assets", systemImage: "trash")
        }
        .confirmationDialog(
            "Confirm clearing downloads (CD jackets)?",
            isPresented: showingBool,
            titleVisibility: .visible
        ){
            Button("Yes", role: .destructive){
                do {
                    let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                                   in: .userDomainMask,
                                                                   appropriateFor: nil,
                                                                   create: false)
                    /* Clear .zip .tmp jackets/ simfiles/ */
                    let fileURLs = try FileManager.default
                        .contentsOfDirectory(at: documentsURL,
                                             includingPropertiesForKeys: nil,
                                             options: .skipsHiddenFiles)
                    
                    for fileURL in fileURLs
                    where fileURL.pathExtension == "tmp"
                    || fileURL.pathExtension == "zip"
                    || fileURL.lastPathComponent == "jackets"
                    || fileURL.lastPathComponent == "simfiles"
                    {
                        try FileManager.default.removeItem(at: fileURL)
                    }
                    viewModel.jacketsDownloaded = false
                } catch {
                    print("failed to clear files")
                }
            }
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
