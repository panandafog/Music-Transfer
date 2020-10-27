//
//  ContentView.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State private var selectionFrom = 0
    @State private var selectionTo = 0
    
    @ObservedObject var manager = APIManager.shared
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("From:")
                        .font(.headline)
                    MenuButton(manager.facades[selectionFrom].apiName) {
                        ForEach(0...(manager.facades.count - 1), id: \.self, content: { ind in
                            Button(action: {
                                self.selectionFrom = ind
                            }, label: {
                                Text(self.manager.facades[ind].apiName)
                            })
                        })
                    }
                    Button(action: {
                        let facade = self.manager.facades[self.selectionFrom]
                        facade.authorize()
                    }, label: {
                        Text("Authorize")
                    })
                    Button(action: {
                        let facade = self.manager.facades[self.selectionFrom]
                        facade.getSavedTracks()
                    }, label: {
                        Text("Get saved tracks")
                    })
                    if manager.facades[selectionFrom].isAuthorised {
                        Text("Authorization complete")
                    }
                    if manager.facades[selectionFrom].gotTracks {
                        Text("Got saved tracks")
                    }
                }
                
                VStack {
                    Text("To:")
                        .font(.headline)
                    MenuButton(manager.facades[selectionTo].apiName) {
                        ForEach(0...(manager.facades.count - 1), id: \.self, content: { ind in
                            Button(action: {
                                self.selectionTo = ind
                            }, label: {
                                Text(self.manager.facades[ind].apiName)
                            })
                        })
                    }
                    Button(action: {
                        let facade = self.manager.facades[self.selectionTo]
                        facade.authorize()
                    }, label: {
                        Text("Authorize")
                    })
                    Button(action: {
                        let facade = self.manager.facades[self.selectionTo]
                        facade.getSavedTracks()
                    }, label: {
                        Text("Get saved tracks")
                    })
                    if manager.facades[selectionTo].isAuthorised {
                        Text("Authorization complete")
                    }
                    if manager.facades[selectionTo].gotTracks {
                        Text("Got saved tracks")
                    }
                }
            }
            TracksTable(selectionFrom: self.$selectionFrom, selectionTo: self.$selectionTo, manager: self.manager)
            ToolsView(selectionFrom: self.$selectionFrom, selectionTo: self.$selectionTo, manager: self.manager)
        }
    }
}

