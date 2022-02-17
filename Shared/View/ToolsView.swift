//
//  ToolsView.swift
//  Music Transfer
//
//  Created by panandafog on 11.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct ToolsView: View {
    
    @ObservedObject var model = TransferManager.shared
    
    @State private var showingAlert1 = false
    @State private var showingAlert2 = false
    
    var serviceFrom: APIService {
        model.services[model.selectionFrom]
    }
    var serviceTo: APIService {
        model.services[model.selectionTo]
    }
    
    var body: some View {
        // swiftlint:disable trailing_closure
        Button(
            // swiftlint:enable trailing_closure
            action: {
                showingAlert1 = true
            }, label: {
                Text("Confirm")
                    .foregroundColor(.background)
            }
        )
            .padding(10)
#if !os(macOS)
            .background(Color.accentColor)
            .cornerRadius(10)
#endif
            .disabled(
                !model.ableToTransfer(
                    from: serviceFrom,
                    to: serviceTo
                )
            )
            .alert(
                isPresented: $showingAlert1,
                content: {
                    Alert(
                        title: Text("Are you sure you want to transfer all tracks?"),
                        message: Text("All your tracks from \(type(of: serviceFrom).apiName) "
                                      + "would be added to \(type(of: serviceTo).apiName)."),
                        primaryButton: .destructive(Text("Transfer")) {
                            DispatchQueue.global(qos: .background).async { [self] in
                                model.transfer(
                                    from: serviceFrom,
                                    to: serviceTo
                                )
                            }
                        },
                        secondaryButton: .cancel())
                }
            )
    }
}
