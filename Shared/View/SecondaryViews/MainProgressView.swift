//
//  ProgressView.swift
//  Music Transfer
//
//  Created by panandafog on 04.01.2021.
//  Copyright © 2021 panandafog. All rights reserved.
//

import SwiftUI

struct MainProgressView: View {
    @ObservedObject var model = TransferManager.shared
    
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

// swiftlint:disable type_name
struct MainProgressView_Preview: PreviewProvider {
    static let model: TransferManager = {
        let model = TransferManager.shared
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
