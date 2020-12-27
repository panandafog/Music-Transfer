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
    
    @ObservedObject var manager = APIManager.shared
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading,
                       spacing: nil,
                       content: {
                        Text("From:")
                            .font(.title)
                        HStack {
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
                            Spacer()
                        }
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
                       })
                    .padding()
                
                VStack(alignment: .leading, spacing: nil, content: {
                    Text("To:")
                        .font(.title)
                    HStack {
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
                        Spacer()
                    }
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
                })
                .padding([.top, .horizontal])
            }
            TracksTable(tracks: .init(get: {
                manager.facades[selectionFrom].savedTracks
            }, set: { _ in }), name: "Saved tracks:")
            ToolsView(selectionFrom: $selectionFrom, selectionTo: $selectionTo, manager: manager)
        }
    }
}
