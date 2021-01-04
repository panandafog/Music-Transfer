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
    @ObservedObject var model: ContentView.ContentViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
            Button(action: {
                DispatchQueue.global(qos: .background).async {
                    self.model.facades[self.selectionTo]
                        .addTracks(self.model.facades[self.selectionFrom].savedTracks)
                }
            }, label: {
                Text("Transfer")
            }).disabled(!self.model.facades[self.selectionFrom].gotTracks
                            || !self.model.facades[self.selectionTo].isAuthorised)
            
            Button(action: {
                DispatchQueue.global(qos: .background).async {
                    self.model.facades[self.selectionTo]
                        .synchroniseTracks(self.model.facades[self.selectionFrom].savedTracks)
                }
            }, label: {
                Text("Synchronise")
            }).disabled(!self.model.facades[self.selectionFrom].gotTracks
                            || !self.model.facades[self.selectionTo].gotTracks)
        })
        .padding(.bottom)
    }
}
