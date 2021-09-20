//
//  TransferView.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct TransferView: View {
    
    @State private var selectionFrom = 0
    @State private var selectionTo = 1
    
    @State private var showingAlert1 = false
    @State private var showingAlert2 = false
    
    @ObservedObject private var model = TransferState.shared
    
    @State private var showingAuthorization1 = false
    @State private var showingAuthorization2 = false
    
    private static let menuMaxWidth = CGFloat(100)
    
    var firstServiceView: some View {
        VStack(spacing: nil, content: {
            HStack {
                Text("From:")
                    .font(.title)
                #if !os(macOS)
                Spacer()
                #endif
                Menu {
                    ForEach(0...(model.facades.count - 1), id: \.self, content: { ind in
                        Button(action: {
                            selectionFrom = ind
                            if selectionTo == ind {
                                if selectionTo == model.facades.count - 1 {
                                    selectionTo = 0
                                } else {
                                    selectionTo += 1
                                }
                            }
                        }, label: {
                            Text(model.facades[ind].apiName)
                        })
                    })
                } label: {
                    Label(model.facades[selectionFrom].apiName, systemImage: "chevron.down")
                }
                .modify {
                    #if os(macOS)
                    $0
                        .frame(maxWidth: Self.menuMaxWidth)
                        .padding(.leading)
                    #endif
                }
                
                #if os(macOS)
                Spacer()
                #endif
            }
            HStack {
                Button(action: {
                    showingAuthorization1 = true
                }, label: {
                    Text("Authorize")
                })
                .sheet(isPresented: $showingAuthorization1) {
                    model.facades[selectionFrom].authorize()
                }
                Button(action: {
                    let facade = model.facades[selectionFrom]
                    DispatchQueue.global(qos: .background).async {
                        facade.getSavedTracks()
                    }
                }, label: {
                    Text("Get saved tracks")
                })
                .disabled(!model.facades[selectionFrom].isAuthorised
                            || model.operationInProgress)
                NavigationLink("View saved tracks", destination:
                                TracksTable(tracks: .init(get: {
                                    model.facades[selectionFrom].savedTracks
                                }, set: { _ in }), name: "Saved tracks:"))
                    .disabled(!model.facades[selectionFrom].gotTracks
                                || model.operationInProgress)
                Button(action: {
                    self.showingAlert1 = true
                }, label: {
                    Text("Delete all tracks")
                })
                .disabled(!model.facades[selectionFrom].gotTracks
                            || model.operationInProgress)
                .alert(isPresented: $showingAlert1, content: {
                    Alert(title: Text("Are you sure you want to delete all tracks?"),
                          message: Text("There is no undo"),
                          primaryButton: .destructive(Text("Delete")) {
                            let facade = model.facades[selectionFrom]
                            DispatchQueue.global(qos: .background).async {
                                facade.deleteAllTracks()
                            }
                          },
                          secondaryButton: .cancel())
                })
            }
            TracksTable(tracks: .init(get: {
                model.facades[selectionFrom].savedTracks
            }, set: { _ in }), name: "Saved tracks:")
        })
        .padding(.horizontal)
    }
    
    var secondServiceView: some View {
        VStack(spacing: nil, content: {
            HStack {
                Text("To:")
                    .font(.title)
                #if !os(macOS)
                Spacer()
                #endif
                Menu {
                    ForEach(0...(model.facades.count - 1), id: \.self, content: { ind in
                        Button(action: {
                            selectionTo = ind
                        }, label: {
                            Text(model.facades[ind].apiName)
                        })
                        .disabled(selectionFrom == ind)
                    })
                } label: {
                    Label(model.facades[selectionTo].apiName, systemImage: "chevron.down")
                }
                .modify {
                    #if os(macOS)
                    $0
                        .frame(maxWidth: Self.menuMaxWidth)
                        .padding(.leading)
                    #endif
                }
                
                #if os(macOS)
                Spacer()
                #endif
            }
            HStack {
                Button(action: {
                    showingAuthorization2 = true
                }, label: {
                    Text("Authorize")
                })
                .sheet(isPresented: $showingAuthorization2) {
                    model.facades[selectionTo].authorize()
                }
                Button(action: {
                    let facade = model.facades[selectionTo]
                    DispatchQueue.global(qos: .background).async {
                        facade.getSavedTracks()
                    }
                }, label: {
                    Text("Get saved tracks")
                })
                .disabled(!model.facades[selectionTo].isAuthorised
                            || model.operationInProgress)
                NavigationLink("View saved tracks", destination:
                                TracksTable(tracks: .init(get: {
                                    model.facades[selectionTo].savedTracks
                                }, set: { _ in }), name: "Saved tracks:"))
                    .disabled(!model.facades[selectionTo].gotTracks
                                || model.operationInProgress)
                Button(action: {
                    self.showingAlert2 = true
                }, label: {
                    Text("Delete all tracks")
                })
                .disabled(!model.facades[selectionTo].gotTracks
                            || model.operationInProgress)
                .alert(isPresented: $showingAlert2, content: {
                    Alert(title: Text("Are you sure you want to delete all tracks?"),
                          message: Text("There is no undo"),
                          primaryButton: .destructive(Text("Delete")) {
                            let facade = model.facades[selectionTo]
                            DispatchQueue.global(qos: .background).async {
                                facade.deleteAllTracks()
                            }
                          },
                          secondaryButton: .cancel())
                })
            }
            TracksTable(tracks: .init(get: {
                model.facades[selectionTo].savedTracks
            }, set: { _ in }), name: " ")
        })
        .padding(.horizontal)
    }
    
    var bottomView: some View {
        Group {
            if model.captcha != nil {
                CaptchaRequestView(openCaptcha: {
                    model.solvingCaptcha = true
                })
                .padding()
                .sheet(isPresented: $model.solvingCaptcha) {
                    CaptchaView(captcha: model.captcha!) {
                        model.solvingCaptcha = false
                        model.captcha = nil
                    }
                }
            } else {
                if model.active {
                    MainProgressView()
                        .padding()
                } else {
                    ToolsView(selectionFrom: $selectionFrom, selectionTo: $selectionTo, model: model)
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            
            #if os(macOS)
            HStack {
                firstServiceView
                secondServiceView
            }
            #else
            firstServiceView
            secondServiceView
            #endif
            
            Spacer()
            
            bottomView
        }
    }
}
