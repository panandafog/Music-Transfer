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
                List {
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
                        self.manager.facades[self.selectionFrom].authorize()
                    }, label: {
                        Text("Authorize")
                    })
                    if manager.facades[selectionFrom].isAuthorised {
                        Text("Authorization complete")
                    }
                }
                
                List {
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
                        self.manager.facades[self.selectionTo].authorize()
                    }, label: {
                        Text("Authorize")
                    })
                    if manager.facades[selectionTo].isAuthorised {
                        Text("Authorization complete")
                    }
                }
            }
            TracksView(selectionFrom: self.$selectionFrom, selectionTo: self.$selectionTo, manager: self.manager)
        }
    }
}

