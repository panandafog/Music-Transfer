//
//  ToolsView.swift
//  Music Transfer
//
//  Created by panandafog on 11.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct ToolsView: View {
    
    @Binding var selectionFrom: Int
    @Binding var selectionTo: Int
    @ObservedObject var model: TransferManager
    
    @State private var showingAlert1 = false
    @State private var showingAlert2 = false
    
    var body: some View {
        
        HStack(
            alignment: .center,
            spacing: nil
        ) {
            // swiftlint:disable trailing_closure
            Button(
                // swiftlint:enable trailing_closure
                action: {
                    showingAlert1 = true
                }, label: {
                    Text("Transfer")
                }
            )
                .disabled(
                    !model.ableToTransfer(
                        from: model.services[selectionFrom],
                        to: model.services[selectionTo]
                    )
                )
                .alert(
                    isPresented: $showingAlert1,
                    content: {
                        Alert(
                            title: Text("Are you sure you want to transfer all tracks?"),
                            message: Text("All your tracks from \(model.services[selectionFrom].apiName) "
                                          + "would be added to \(model.services[selectionTo].apiName)."),
                            primaryButton: .destructive(Text("Transfer")) {
                                DispatchQueue.global(qos: .background).async { [self] in
                                    model.transfer(
                                        from: model.services[selectionFrom],
                                        to: model.services[selectionTo]
                                    )
                                }
                            },
                            secondaryButton: .cancel())
                    }
                )
        }
        .padding(.bottom)
    }
}
