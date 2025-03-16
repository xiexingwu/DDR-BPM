//
//  SettingView.swift
//  DDR BPM
//
//  Created by Michael Xie on 9/5/2022.
//

import Introspect
import SwiftUI

enum FocusField: Hashable {
    case readSpeedField
}
enum ShowingConfirmation: Hashable {
    case none
    case clearFavs
    case deleteJackets
    case downloadAssets
    case checkUpdates
    case resetApp
}

enum UpdateStatus: String {
    case none
    case checking
    case notavailable
    case available
    case progressing
    case success
    case fail
}

struct SettingView: View {

    @State private var showingConfirmation: ShowingConfirmation = .none
    @FocusState private var focusedField: FocusField?

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section { ReadSpeedInput(focusedField: _focusedField) }

                    Section { UpdateButtons() }

                    Section { ClearFavsButton(showing: $showingConfirmation) }

                    Section { ResetAppButton(showing: $showingConfirmation) }

                    Section {
                        Link(
                            destination: URL(string: "https://github.com/xiexingwu/DDR-BPM-issues")!
                        ) {
                            Label("Report bug / Give feedback", systemImage: "ant")
                        }
                        Link(
                            destination: URL(
                                string:
                                    "https://www.paypal.com/donate/?hosted_button_id=2R64RY6ZL52EW")!
                        ) {
                            Label("Support me (PayPal)", systemImage: "dollarsign.circle")
                        }
                    }
                }
                .introspectTableView { tableView in
                    tableView.keyboardDismissMode = .onDrag
                }

            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }

    }
}

struct ReadSpeedInput: View {
    @EnvironmentObject var viewModel: ViewModel
    @FocusState var focusedField: FocusField?

    @State private var tempReadSpeed: Int?
    @State private var alertInvalidReadSpeed: Bool = false
    @State private var alertValidReadSpeed: Bool = false

    private func validInput() -> Bool {
        if tempReadSpeed != nil {
            return tempReadSpeed! > 0
        } else {
            return false
        }
    }

    var body: some View {
        HStack {
            Text("Set read speed:")
                .onTapGesture {
                    focusedField = .readSpeedField
                }

            TextField(
                viewModel.userReadSpeed.formatted(),
                value: $tempReadSpeed,
                format: .number
            )
            .keyboardType(.numberPad)
            .focused($focusedField, equals: .readSpeedField)
            .frame(maxWidth: .infinity)
            .onChange(of: focusedField) { newFocus in
                if newFocus != .readSpeedField {
                    tempReadSpeed = nil
                }
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    ToolbarKeyboard(cancelAction: { focusedField = .none })
                }
            }

            Button {
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
            .alert("Invalid read speed.", isPresented: $alertInvalidReadSpeed) {
                Button("OK", role: .cancel) {
                    focusedField = .readSpeedField
                }
            }
            .alert("Read speed set to \(tempReadSpeed ?? 0).", isPresented: $alertValidReadSpeed) {
                Button("OK", role: .cancel) { tempReadSpeed = nil }
            }
        }
    }

}

struct ClearFavsButton: View {
    @EnvironmentObject var favorites: Favorites
    @Binding var showing: ShowingConfirmation

    var body: some View {
        let showingBool = Binding(
            get: { showing == .clearFavs }, set: { showing = $0 ? .clearFavs : .none })
        Button(role: .destructive) {
            showing = .clearFavs
        } label: {
            Label("Clear favorites", systemImage: "trash")
        }
        .confirmationDialog(
            "Confirm clearing favorites?",
            isPresented: showingBool,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive) {
                favorites.clear()
            }
        }
    }
}

struct UpdateButtons: View {

    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var viewModel: ViewModel

    private let downloader = BackgroundDownloader.shared

    var body: some View {
        CheckUpdatesButton
    }

    var CheckUpdatesButton: some View {
        let systemImage: String = "arrow.triangle.2.circlepath"
        let labelText: String = {
            switch viewModel.updateStatus {
            case .none:
                return "Check for update."
            case .checking:
                return "Checking for update..."
            case .notavailable:
                return "No update available. Check again?"
            case .available:
                return "Update available"
            case .progressing:
                return
                    "Updating... \(formatBytes(viewModel.downloadProgressBytes.0))/\(formatBytes(viewModel.downloadProgressBytes.1))"
            case .success:
                return "Update finished. Check again?"
            case .fail:
                return "Update failed. Restart?"
            }
        }()

        return AsyncButton {
            switch viewModel.updateStatus {
            case .none, .notavailable, .success, .fail:
                viewModel.updateStatus = .checking
                viewModel.updateStatus = await checkUpdate()
            case .available:
                viewModel.updateStatus = .progressing
                downloader.downloadAsset(
                    etagStore: .data, viewModel: viewModel, modelData: modelData)
                downloader.downloadAsset(
                    etagStore: .jackets, viewModel: viewModel, modelData: modelData, isLast: true)
            case .checking, .progressing:
                ()
            }
        } label: {
            Label(labelText, systemImage: systemImage)
        }
        .disabled(
            [.checking, .progressing].contains(viewModel.updateStatus)
        )
    }

    private func checkUpdate() async -> UpdateStatus {
        do {
            var etag: String

            etag = try await fetchEtag(STORE + DATA_ZIP)
            let dataUpdated = (etag != modelData.dataEtag)
            defaultLogger.debug("new data etag: \(etag)")
            defaultLogger.debug("old data etag: \(modelData.dataEtag)")
            defaultLogger.debug("Update needed: \(dataUpdated)")

            etag = try await fetchEtag(STORE + JACKETS_ZIP)
            let jacketsUpdated = (etag != modelData.jacketsEtag)
            defaultLogger.debug("new jackets etag: \(etag)")
            defaultLogger.debug("old jackets etag: \(modelData.jacketsEtag)")
            defaultLogger.debug("Update needed: \(jacketsUpdated )")

            return dataUpdated || jacketsUpdated ? .available : .notavailable
        } catch {
            defaultLogger.error("Failed to check update")
            return .available
        }
    }
}

struct ResetAppButton: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var favorites: Favorites
    @Binding var showing: ShowingConfirmation

    @State private var showingPostReset: Bool = false

    var body: some View {
        let showingBool = Binding(
            get: { showing == .resetApp }, set: { showing = $0 ? .resetApp : .none })
        Button(role: .destructive) {
            showing = .resetApp
        } label: {
            Label("Reset app", systemImage: "trash")
        }
        .confirmationDialog(
            "This will reset all app settings and delete all data.\nProceed?",
            isPresented: showingBool,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive) {
                modelData.reset()
                viewModel.reset()
                favorites.clear()
                showingPostReset = true
            }
        }
        .alert("Please close and restart the app.", isPresented: $showingPostReset) {
            Button("OK", role: .cancel) {
                ()
            }
        }
    }
}
