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
    case deleteJackets
    case downloadAssets
    case checkUpdates
    case resetApp
}

struct SettingView: View {
    
    @State private var showingConfirmation: ShowingConfirmation = .none
    @FocusState private var focusedField : FocusField?
    
    
    var body: some View { NavigationView{
        VStack{
            List{
                Section{
                    ReadSpeedInput(focusedField: _focusedField)
                }

                Section{
                    UpdateButtons(showing: $showingConfirmation)
                    AssetsButton(showing: $showingConfirmation)
                }
            
                Section{
                    ClearFavsButton(showing: $showingConfirmation)
//                    ClearCoursesButton(showing: $showingConfirmation)

                }
                
                Section{
                    ResetAppButton(showing: $showingConfirmation)
                }

                Section{
                    Link(destination: URL(string: "https://github.com/xiexingwu/DDR-BPM-issues")!) {
                        Label("Report bug / Give feedback", systemImage: "ant")
                    }
                    Link(destination: URL(string: "https://www.paypal.com/donate/?hosted_button_id=2R64RY6ZL52EW")!){
                        Label("Support me (PayPal)", systemImage: "dollarsign.circle")
                    }
                }
            }
            
        }
        .navigationBarTitle("Settings")
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
        
        if viewModel.jacketsDownloaded{
            DeleteJacketsButton
        } else {
            DownloadAssetsButton
        }
    }
    
    var DownloadAssetsButton : some View {
        let showingBool = Binding(get: {showing == .downloadAssets}, set: {showing = $0 ? .downloadAssets : .none})
        return Button{
            showing = viewModel.downloadProgress < 0 ? .downloadAssets : .none
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
        .disabled(viewModel.updateStatus == .progressing || viewModel.assetsStatus == .progressing || viewModel.updateStatus == .checking || viewModel.assetsStatus == .checking)
        .confirmationDialog(
            "Download CD jackets (Approx \(ASSETS_SIZE)?",
            isPresented: showingBool,
            titleVisibility: .visible
        ){
            Button("Yes", role: .destructive){
                downloader.downloadJacketsZip()
            }
        }
    }
    
    var DeleteJacketsButton : some View {
        let showingBool = Binding(get: {showing == .deleteJackets}, set: {showing = $0 ? .deleteJackets : .none})
        return Button(role: .destructive){
            showing = .deleteJackets
        } label: {
            Label("Delete CD Jackets", systemImage: "trash")
        }
        .confirmationDialog(
            "Confirm clearing downloads (CD jackets)?",
            isPresented: showingBool,
            titleVisibility: .visible
        ){
            Button("Yes", role: .destructive){
                do {
                    // Delete legacy jacket folder
                    try? FileManager.default.removeItem(at: DOCUMENTS_URL.appendingPathComponent("jackets"))
                    try FileManager.default.removeItem(at: JACKETS_FOLDER_URL)

                    viewModel.jacketsDownloaded = false
                } catch {
                    defaultLogger.error("failed to delete jackets.")
                }
            }
        }
    }
}


struct UpdateButtons : View {
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel
    @Binding var showing: ShowingConfirmation
    
    private let downloader = AssetsDownloader.shared

    var body: some View {
        Group {
            CheckUpdatesButton
            VerifyFilesButton
        }
    }
    
    var CheckUpdatesButton : some View {
        let systemImage: String = "arrow.triangle.2.circlepath"
        let labelText: String = {
            switch viewModel.updateStatus{
            case .checking:
                return "Checking for updates..."
            case .available:
                return "Updates available"
            case .progressing:
                return "Updating..."
            case .success:
                return "Up to date"
            case .fail:
                return "Update failed (Try again)"
            default:
                return "Check updates"
            }
        }()
        
        return AsyncButton() {
            switch viewModel.updateStatus {
            case .available:
                await downloader.updateAssets()
            case .checking, .progressing:
                ()
            case .fail:
                await downloader.checkUpdates()
                await downloader.updateAssets()
            default:
                await downloader.checkUpdates()
            }
        } label: {
            HStack{
                Label(labelText, systemImage: systemImage)
            }
        }
        .disabled(viewModel.updateStatus == .progressing || viewModel.assetsStatus == .progressing || viewModel.updateStatus == .checking || viewModel.assetsStatus == .checking)
    }
    
    
    var VerifyFilesButton: some View {
        let systemImage: String = "wrench.and.screwdriver"
        let labelText: String = {
            switch viewModel.assetsStatus{
            case .checking:
                return "Checking for broken files..."
            case .available:
                return "Fix missing/broken files"
            case .progressing:
                return "Fixing..."
            case .success:
                return "Files OK"
            case .fail:
                return "Files still broken (Try again)"
            default:
                return "Check for broken files"
            }
        }()
        
        return AsyncButton() {
            switch viewModel.assetsStatus {
            case .available:
                await downloader.updateAssets(fix: true)
            case .checking, .progressing:
                ()
            case .fail:
                await downloader.checkUpdates(checkHashes: true)
                await downloader.updateAssets(fix: true)
            default:
                await downloader.checkUpdates(checkHashes: true)
            }
        } label: {
            HStack{
                Label(labelText, systemImage: systemImage)
            }
        }
        .disabled(viewModel.updateStatus == .progressing || viewModel.assetsStatus == .progressing || viewModel.updateStatus == .checking || viewModel.assetsStatus == .checking)
    }

}

struct ResetAppButton : View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var favorites: Favorites
    @Binding var showing: ShowingConfirmation
    
    @State private var showingPostReset: Bool = false
    
    var body: some View {
        let showingBool = Binding(get: {showing == .resetApp}, set: {showing = $0 ? .resetApp : .none})
        Button(role: .destructive){
            showing = .resetApp
        } label:{
            Label("Reset app", systemImage: "trash")
        }
        .confirmationDialog(
            "This will reset all app settings and delete all data.\nProceed?",
            isPresented: showingBool,
            titleVisibility: .visible
        ){
            Button("Yes", role: .destructive){
                modelData.reset()
                viewModel.reset()
                favorites.clear()
                showingPostReset = true
            }
        }
        .alert("Please close and restart the app.", isPresented: $showingPostReset){
            Button("OK", role: .cancel) {
                ()
            }
        }
    }
}
