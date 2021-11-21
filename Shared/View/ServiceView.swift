//
//  ServiceView.swift
//  Music Transfer
//
//  Created by panandafog on 21.11.2021.
//

import SwiftUI

struct ServiceView: View {
    private static let menuMaxWidth = CGFloat(100)
    
    let serviceType: ServiceType
    var selection: Int {
        switch serviceType {
        case .primary:
            return model.selectionFrom
        case .secondary:
            return model.selectionTo
        }
    }
    var service: APIService {
        model.services[selection]
    }
    
    @ObservedObject private var model = TransferManager.shared
    @State private var showingAlert = false
    
    var body: some View {
        VStack(spacing: nil) {
            HStack {
                Text("From:")
                    .font(.title)
#if !os(macOS)
                Spacer()
#endif
                Menu {
                    ForEach(0...(model.services.count - 1), id: \.self) { index in
                        Button(action: {
                            switch serviceType {
                            case .primary:
                                model.selectionFrom = index
                                if model.selectionTo == index {
                                    if model.selectionTo == model.services.count - 1 {
                                        model.selectionTo = 0
                                    } else {
                                        model.selectionTo += 1
                                    }
                                }
                            case .secondary:
                                model.selectionTo = index
                            }
                        }, label: {
                            Text(type(of: model.services[index]).apiName)
                        })
                            .modify {
                                switch serviceType {
                                case .primary:
                                    $0
                                case .secondary:
                                    $0.disabled(selection == index)
                                }
                            }
                    }
                } label: {
                    Label(type(of: service).apiName, systemImage: "chevron.down")
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
                    var service = service
                    service.showingAuthorization = true
                }, label: {
                    Text("Authorize")
                })
                    .sheet(isPresented: $model.services[selection].showingAuthorization) {
                        service.authorize()
                    }
                Button(action: {
                    DispatchQueue.global(qos: .background).async {
                        service.getSavedTracks()
                    }
                }, label: {
                    Text("Get saved tracks")
                })
                    .disabled(!service.isAuthorised
                              || model.operationInProgress)
#if !os(macOS)
                NavigationLink("View saved tracks", destination:
                                TracksTable(tracks: .init(get: {
                    service.savedTracks
                }, set: { _ in }), name: "Saved tracks:"))
                    .disabled(!service.gotTracks
                              || model.operationInProgress)
#endif
                // swiftlint:disable trailing_closure
                Button(
                    // swiftlint:enable trailing_closure
                    action: {
                        showingAlert = true
                    },
                    label: {
                        Text("Delete all tracks")
                    }
                )
                    .disabled(!service.gotTracks
                              || model.operationInProgress)
                    .alert(isPresented: $showingAlert, content: {
                        Alert(title: Text("Are you sure you want to delete all tracks?"),
                              message: Text("There is no undo"),
                              primaryButton:
                                    .destructive(Text("Delete")) {
                                        DispatchQueue.global(qos: .background).async {
                                            service.deleteAllTracks()
                                        }
                                    },
                              secondaryButton: .cancel()
                        )
                    })
            }
#if os(macOS)
            TracksTable(tracks: .init(get: {
                service.savedTracks
            }, set: { _ in }), name: "Saved tracks:")
#endif
        }
        .padding(.horizontal)
    }
}

extension ServiceView {
    enum ServiceType {
        case primary
        case secondary
    }
}
