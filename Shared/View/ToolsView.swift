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
    @ObservedObject var model: TransferState
    
    @State private var showingAlert1 = false
    @State private var showingAlert2 = false
    
    var body: some View {
        HStack(alignment: .center, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
            Button(action: {
                self.showingAlert1 = true
            }, label: {
                Text("Transfer")
            })
            .disabled(!self.model.facades[self.selectionFrom].gotTracks
                            || !self.model.facades[self.selectionTo].isAuthorised
                            || model.operationInProgress)
            .alert(isPresented: $showingAlert1, content: {
                Alert(title: Text("Are you sure you want to transfer all tracks?"),
                      message: Text("All your tracks from \(self.model.facades[self.selectionFrom].apiName) "
                      + "would be added to \(self.model.facades[self.selectionTo].apiName)."),
                      primaryButton: .destructive(Text("Transfer")) {
                        DispatchQueue.global(qos: .background).async {
                            self.model.facades[self.selectionTo]
                                .addTracks(self.model.facades[self.selectionFrom].savedTracks)
                        }
                      },
                      secondaryButton: .cancel())
            })
            
            Button(action: {
                self.showingAlert2 = true
            }, label: {
                Text("Synchronise")
            })
            .disabled(!self.model.facades[self.selectionFrom].gotTracks
                            || !self.model.facades[self.selectionTo].gotTracks
                            || model.operationInProgress)
            .alert(isPresented: $showingAlert2, content: {
                Alert(title: Text("Are you sure you want to synchronise all tracks?"),
                      message: Text("All your tracks from \(self.model.facades[self.selectionFrom].apiName) "
                      + "would be added to \(self.model.facades[self.selectionTo].apiName), if they are not added yet."),
                      primaryButton: .destructive(Text("Synchronise")) {
                        DispatchQueue.global(qos: .background).async {
                            self.model.facades[self.selectionTo]
                                .synchroniseTracks(self.model.facades[self.selectionFrom].savedTracks)
                        }
                      },
                      secondaryButton: .cancel())
            })
        })
        .padding(.bottom)
    }
}
