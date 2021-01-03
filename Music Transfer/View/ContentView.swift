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
    @State private var selectionTo = 1
    
    @State private var showingAlert1 = false
    @State private var showingAlert2 = false
    
    @ObservedObject var manager = APIManager.shared
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading,
                       spacing: nil,
                       content: {
                        HStack {
                            Text("From:")
                                .font(.title)
                            MenuButton(manager.facades[selectionFrom].apiName) {
                                ForEach(0...(manager.facades.count - 1), id: \.self, content: { ind in
                                    Button(action: {
                                        selectionFrom = ind
                                        if selectionTo == ind {
                                            if selectionTo == manager.facades.count - 1 {
                                                selectionTo = 0
                                            } else {
                                                selectionTo += 1
                                            }
                                        }
                                    }, label: {
                                        Text(manager.facades[ind].apiName)
                                    })
                                })
                            }
                            .frame(width: 100)
                            .padding(.leading)
                        }
                        .padding([.top, .leading, .trailing])
                        HStack {
                            Button(action: {
                                let facade = manager.facades[selectionFrom]
                                facade.authorize()
                            }, label: {
                                Text("Authorize")
                            })
                            Button(action: {
                                let facade = manager.facades[selectionFrom]
                                facade.getSavedTracks()
                            }, label: {
                                Text("Get saved tracks")
                            })
                            .disabled(!manager.facades[selectionFrom].isAuthorised)
                            Button(action: {
                                self.showingAlert1 = true
                            }, label: {
                                Text("Delete all tracks")
                            })
                            .alert(isPresented: $showingAlert1, content: {
                                Alert(title: Text("Are you sure you want to delete all tracks?"),
                                      message: Text("There is no undo"),
                                      primaryButton: .destructive(Text("Delete")) {
                                        let facade = manager.facades[selectionFrom]
                                        facade.deleteAllTracks()
                                      },
                                      secondaryButton: .cancel())
                            })
                            .disabled(!manager.facades[selectionFrom].gotTracks)
                            Spacer()
                        }
                        .padding(.horizontal)
                        TracksTable(tracks: .init(get: {
                            manager.facades[selectionFrom].savedTracks
                        }, set: { _ in }), name: "Saved tracks:")
                       })
                
                VStack(alignment: .leading, spacing: nil, content: {
                    HStack {
                        Text("To:")
                            .font(.title)
                        MenuButton(manager.facades[selectionTo].apiName) {
                            ForEach(0...(manager.facades.count - 1), id: \.self, content: { ind in
                                Button(action: {
                                    selectionTo = ind
                                }, label: {
                                    Text(manager.facades[ind].apiName)
                                })
                                .disabled(selectionFrom == ind)
                            })
                        }
                        .frame(width: 100)
                        .padding(.leading)
                    }
                    .padding([.top, .leading, .trailing])
                    HStack {
                        Button(action: {
                            let facade = manager.facades[selectionTo]
                            facade.authorize()
                        }, label: {
                            Text("Authorize")
                        })
                        Button(action: {
                            let facade = manager.facades[selectionTo]
                            facade.getSavedTracks()
                        }, label: {
                            Text("Get saved tracks")
                        })
                        .disabled(!manager.facades[selectionTo].isAuthorised)
                        Button(action: {
                            self.showingAlert2 = true
                        }, label: {
                            Text("Delete all tracks")
                        })
                        .alert(isPresented: $showingAlert2, content: {
                            Alert(title: Text("Are you sure you want to delete all tracks?"),
                                  message: Text("There is no undo"),
                                  primaryButton: .destructive(Text("Delete")) {
                                    let facade = manager.facades[selectionTo]
                                    facade.deleteAllTracks()
                                  },
                                  secondaryButton: .cancel())
                        })
                        .disabled(!manager.facades[selectionTo].gotTracks)
                    }
                    .padding(.horizontal)
                    TracksTable(tracks: .init(get: {
                        manager.facades[selectionTo].savedTracks
                    }, set: { _ in }), name: " ")
                })
            }
        }
        ToolsView(selectionFrom: $selectionFrom, selectionTo: $selectionTo, manager: manager)
    }
}
