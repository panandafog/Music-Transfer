//
//  TracksView.swift
//  Music Transfer
//
//  Created by panandafog on 11.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct TracksView: View {

    @Binding var selectionFrom: Int
    @Binding var selectionTo: Int
    @ObservedObject var manager: APIManager

    var body: some View {
        List {
            Button(action: {
                self.manager.facades[self.selectionFrom].getSavedTracks()
            }, label: {
                Text("Get all tracks")
            }).disabled(!self.manager.facades[self.selectionFrom].isAuthorised)

            Button(action: {
                self.manager.facades[self.selectionFrom].getSavedTracks()
                self.manager.facades[self.selectionTo].getSavedTracks()
            }, label: {
                Text("Compare tracks")
            }).disabled(!self.manager.facades[self.selectionFrom].isAuthorised ||
                            !self.manager.facades[self.selectionTo].isAuthorised)

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
        }
    }
}
