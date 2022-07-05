//
//  AsyncButton.swift
//  DDR BPM
//
//  Created by Michael Xie on 27/6/2022.
//

import SwiftUI

extension AsyncButton {
    enum ActionOption: CaseIterable {
        case disableButton
        case showProgressView
    }
}

struct AsyncButton<Label: View>: View {
    var actionOptions = Set(ActionOption.allCases)
    var action: () async -> Void
    @ViewBuilder var label: () -> Label
    
    @State private var isDisabled = false
    @State private var showProgressView = false
    
    var body: some View {
        Button(
            action: {
                if actionOptions.contains(.disableButton) {
                    isDisabled = true
                }
            
                Task {
                    var progressViewTask: Task<Void, Error>?

                    if actionOptions.contains(.showProgressView) {
                        progressViewTask = Task {
                            try await Task.sleep(nanoseconds: 150_000_000)
                            showProgressView = true
                        }
                    }

                    await action()
                    progressViewTask?.cancel()

                    isDisabled = false
                    showProgressView = false
                }
            },
            label: {
                HStack {
                    label()
                    
                    if showProgressView {
                        Spacer()
                        ProgressView()
                    }
                }
            }
        )
        .disabled(isDisabled)
    }
}

extension AsyncButton where Label == Text {
    init(_ label: String,
         actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
         action: @escaping () async -> Void) {
        self.init(action: action) {
            Text(label)
        }
    }
}

//extension AsyncButton where Label == Image {
//    init(systemImageName: String,
//         actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
//         action: @escaping () async -> Void) {
//        self.init(action: action) {
//            Image(systemName: systemImageName)
//        }
//    }
//}
