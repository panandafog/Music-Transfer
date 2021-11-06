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
        HStack(alignment: .center, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
            Button(action: {
                self.showingAlert1 = true
            }, label: {
                Text("Transfer")
            })
                .disabled(!self.model.services[self.selectionFrom].gotTracks
                          || !self.model.services[self.selectionTo].isAuthorised
                          || model.operationInProgress)
                .alert(isPresented: $showingAlert1, content: {
                    Alert(title: Text("Are you sure you want to transfer all tracks?"),
                          message: Text("All your tracks from \(self.model.services[self.selectionFrom].apiName) "
                                        + "would be added to \(self.model.services[self.selectionTo].apiName)."),
                          primaryButton: .destructive(Text("Transfer")) {
                        DispatchQueue.global(qos: .background).async {
                            self.model.transfer(
                                from: self.model.services[self.selectionFrom],
                                to: self.model.services[self.selectionTo]
                            )
                        }
                    },
                          secondaryButton: .cancel())
                })
        })
            .padding(.bottom)
    }
}
