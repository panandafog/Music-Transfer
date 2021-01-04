//
//  ProgressView.swift
//  Music Transfer
//
//  Created by panandafog on 04.01.2021.
//  Copyright © 2021 panandafog. All rights reserved.
//

import SwiftUI

struct MainProgressView: View {
    @ObservedObject var model = MainProgressViewModel.shared
    
    var body: some View {
        HStack {
            Text(model.processName)
            if model.active {
                if model.determinate {
                    ProgressView("",
                                 value: model.progressPercentage,
                                 total: 100.0)
                        .padding([.leading])
                } else {
                    ProgressView("")
                        .padding([.top, .leading])
                    Spacer()
                }
            }
        }
        .frame(height: 40)
    }
}

extension MainProgressView {
    class MainProgressViewModel: ObservableObject {
        @Published var progressPercentage = 0.0
        @Published var processName = ""
        @Published var active = false
        @Published var determinate = false
        
        static var shared = MainProgressViewModel()
        
        private init() {}
        
        static func off() {
            let instance = MainProgressViewModel.shared
            instance.off()
        }
        
        func off() {
            self.progressPercentage = 0.0
            self.processName = ""
            self.active = false
            self.determinate = false
        }
    }
}

struct MainProgressView_Preview: PreviewProvider {
    static let model: MainProgressView.MainProgressViewModel = {
        let model = MainProgressView.MainProgressViewModel.shared
        model.determinate = true
        model.processName = "Doing something important"
        model.active = true
        return model
    }()
    
    static var previews: some View {
        Group {
            HStack {
                Text(model.processName)
                ProgressView("",
                             value: model.progressPercentage,
                             total: 100.0)
                    .padding([.leading])
            }
            .frame(height: 40)
        }
        Group {
            HStack(alignment: .center) {
                Text(model.processName)
                ProgressView("")
                    .padding([.top, .leading])
                Spacer()
            }
            .frame(height: 40)
        }
    }
}
