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
    @ObservedObject var manager: APIManager

    var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
            Button(action: {
                self.manager.facades[self.selectionTo].addTracks(self.manager.facades[self.selectionFrom].savedTracks)
            }, label: {
                Text("Transfer")
            }).disabled(!self.manager.facades[self.selectionFrom].gotTracks || !self.manager.facades[self.selectionTo].isAuthorised)

            Button(action: {
                self.manager.facades[self.selectionTo].synchroniseTracks(self.manager.facades[self.selectionFrom].savedTracks)
            }, label: {
                Text("Synchronise")
            }).disabled(!self.manager.facades[self.selectionFrom].gotTracks || !self.manager.facades[self.selectionTo].gotTracks)
        })
        .padding(.bottom)
    }
}
