//
//  CourseView.swift
//  DDR BPM
//
//  Created by Michael Xie on 24/5/2022.
//

import SwiftUI

struct CourseView: View {
    var body: some View {
        NavigableCourseList()
    }
}

struct CourseView_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()
    static var previews: some View {
        CourseView()
            .environmentObject(modelData)
            .environmentObject(favorites)
            .environmentObject(viewModel)
    }
}
