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
                    ForEach(0...(model.services.count - 1), id: \.self, content: { ind in
                        Button(action: {
                            selectionFrom = ind
                            if selectionTo == ind {
                                if selectionTo == model.services.count - 1 {
                                    selectionTo = 0
                                } else {
                                    selectionTo += 1
                                }
                            }
                        }, label: {
                            Text(model.services[ind].apiName)
                        })
                    })
                } label: {
                    Label(model.services[selectionFrom].apiName, systemImage: "chevron.down")
                }
                .modify {
#if os(macOS)
                    $0
                        .frame(maxWidth: Self.menuMaxWidth)
                        .padding(.leading)
#else
                    $0
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
                        model.services[selectionFrom].authorize()
                    }
                Button(action: {
                    let service = model.services[selectionFrom]
                    DispatchQueue.global(qos: .background).async {
                        service.getSavedTracks()
                    }
                }, label: {
                    Text("Get saved tracks")
                })
                    .disabled(!model.services[selectionFrom].isAuthorised
                              || model.operationInProgress)
#if !os(macOS)
                NavigationLink("View saved tracks", destination:
                                TracksTable(tracks: .init(get: {
                    model.services[selectionFrom].savedTracks
                }, set: { _ in }), name: "Saved tracks:"))
                    .disabled(!model.services[selectionFrom].gotTracks
                              || model.operationInProgress)
#endif
                Button(action: {
                    self.showingAlert1 = true
                }, label: {
                    Text("Delete all tracks")
                })
                    .disabled(!model.services[selectionFrom].gotTracks
                              || model.operationInProgress)
                    .alert(isPresented: $showingAlert1, content: {
                        Alert(title: Text("Are you sure you want to delete all tracks?"),
                              message: Text("There is no undo"),
                              primaryButton: .destructive(Text("Delete")) {
                            let service = model.services[selectionFrom]
                            DispatchQueue.global(qos: .background).async {
                                service.deleteAllTracks()
                            }
                        },
                              secondaryButton: .cancel())
                    })
            }
#if os(macOS)
            TracksTable(tracks: .init(get: {
                model.services[selectionFrom].savedTracks
            }, set: { _ in }), name: "Saved tracks:")
#endif
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
                    ForEach(0...(model.services.count - 1), id: \.self, content: { ind in
                        Button(action: {
                            selectionTo = ind
                        }, label: {
                            Text(model.services[ind].apiName)
                        })
                            .disabled(selectionFrom == ind)
                    })
                } label: {
                    Label(model.services[selectionTo].apiName, systemImage: "chevron.down")
                }
                .modify {
#if os(macOS)
                    $0
                        .frame(maxWidth: Self.menuMaxWidth)
                        .padding(.leading)
#else
                    $0
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
                        model.services[selectionTo].authorize()
                    }
                Button(action: {
                    let service = model.services[selectionTo]
                    DispatchQueue.global(qos: .background).async {
                        service.getSavedTracks()
                    }
                }, label: {
                    Text("Get saved tracks")
                })
                    .disabled(!model.services[selectionTo].isAuthorised
                              || model.operationInProgress)
#if !os(macOS)
                NavigationLink("View saved tracks", destination:
                                TracksTable(tracks: .init(get: {
                    model.services[selectionTo].savedTracks
                }, set: { _ in }), name: "Saved tracks:"))
                    .disabled(!model.services[selectionTo].gotTracks
                              || model.operationInProgress)
#endif
                Button(action: {
                    self.showingAlert2 = true
                }, label: {
                    Text("Delete all tracks")
                })
                    .disabled(!model.services[selectionTo].gotTracks
                              || model.operationInProgress)
                    .alert(isPresented: $showingAlert2, content: {
                        Alert(title: Text("Are you sure you want to delete all tracks?"),
                              message: Text("There is no undo"),
                              primaryButton: .destructive(Text("Delete")) {
                            let service = model.services[selectionTo]
                            DispatchQueue.global(qos: .background).async {
                                service.deleteAllTracks()
                            }
                        },
                              secondaryButton: .cancel())
                    })
            }
#if os(macOS)
            TracksTable(tracks: .init(get: {
                model.services[selectionTo].savedTracks
            }, set: { _ in }), name: " ")
#endif
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
