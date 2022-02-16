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
    
    var titleText: String {
        switch serviceType {
        case .primary:
            return "From:"
        case .secondary:
            return "To:"
        }
    }
    
    @ObservedObject private var model = TransferManager.shared
    @State private var showingDeleteAlert = false
    @State private var tracksTableNavigationLinkIsActive = false
    
    var refreshButton: some View {
        AnyView(
            Button(action: {
                DispatchQueue.global(qos: .background).async {
                    service.getSavedTracks()
                }
            }, label: {
                Text("Refresh saved tracks")
            })
                .disabled(!service.isAuthorised
                          || model.operationInProgress)
        )
    }
    
    var viewSavedButton: some View {
        AnyView(
            Button("View saved tracks") {
                self.tracksTableNavigationLinkIsActive = true
            }
                .disabled(!service.gotTracks || model.operationInProgress)
        )
    }
    
    var deleteAllButton: some View {
        AnyView(
            Button(
                action: {
                    showingDeleteAlert = true
                },
                label: {
                    Text("Delete all tracks")
                }
            )
                .disabled(!service.gotTracks
                          || model.operationInProgress)
        )
    }
    
    var logOutButton: some View {
        AnyView(
            Button(action: {
                print("todo")
            }, label: {
                Text("Log out")
            })
                .disabled(!model.services[selection].isAuthorised)
        )
    }
    
    var menuButton: some View {
        AnyView(
            Menu {
                refreshButton
#if !os(macOS)
                viewSavedButton
#endif
                deleteAllButton
                logOutButton
            } label: {
                Label("", systemImage: "square.grid.2x2")
            }
        )
    }
    
    var toolsView: some View {
        AnyView(
            HStack {
                refreshButton
                viewSavedButton
                deleteAllButton
                logOutButton
            }
        )
    }
    
    var tracksPreview: some View {
        if !service.isAuthorised {
            return AnyView(
                Button(action: {
                    var service = service
                    service.showingAuthorization = true
                }, label: {
                    Text("Authorize")
                })
                    .sheet(isPresented: $model.services[selection].showingAuthorization) {
                        AuthorizationView(service: $model.services[selection])
                    }
            )
        } else {
#if os(macOS)
            return AnyView(
                TracksTable(tracks: .init(get: {
                    service.savedTracks
                }, set: { _ in }), name: "Saved tracks:")
            )
#else
            return AnyView(
                TracksTable(
                    tracks: .init(
                        get: {
                            service.savedTracks
                        },
                        set: { _ in }
                    ),
                    name: "Saved tracks:",
                    compact: true
                )
                    .background(Color.background)
                    .cornerRadius(10)
            )
#endif
        }
    }
    
    var body: some View {
        // swiftlint:disable trailing_closure
        VStack(spacing: nil) {
            // swiftlint:enable trailing_closure
            HStack {
                Text(titleText)
                    .font(.title)
#if !os(macOS)
                Spacer()
                menuButton
                    .padding([.horizontal], nil)
#endif
                Menu {
                    ForEach(0...(model.services.count - 1), id: \.self) { index in
                        Button(action: {
                            switch serviceType {
                            case .primary:
                                if model.selectionTo == index {
                                    model.selectionTo = model.selectionFrom
                                }
                                model.selectionFrom = index
                            case .secondary:
                                if model.selectionFrom == index {
                                    model.selectionFrom = model.selectionTo
                                }
                                model.selectionTo = index
                            }
                        }, label: {
                            Text(type(of: model.services[index]).apiName)
                        })
                    }
                } label: {
#if os(macOS)
                    Text(type(of: service).apiName)
#else
                    Label(type(of: service).apiName, systemImage: "chevron.down")
                        .foregroundColor(Color.background)
#endif
                }
#if !os(macOS)
                .padding(10)
                .background(Color.accentColor)
                .cornerRadius(10)
#endif
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
            .padding([.bottom], 10)
#if os(macOS)
                toolsView
#endif
            tracksPreview
#if os(macOS)
            Spacer()
#endif
        }
        .padding(20)
#if !os(macOS)
        .background(Color.secondaryBackground)
#endif
        .cornerRadius(10)
        .background(
            NavigationLink(
                destination: TracksTable(
                    tracks: .init(
                        get: {
                            service.savedTracks
                        },
                        set: { _ in }
                    ),
                    name: "Saved tracks:"),
                isActive: $tracksTableNavigationLinkIsActive
            ) {
                EmptyView()
            }
        )
        .alert(isPresented: $showingDeleteAlert, content: {
            Alert(
                title: Text("Are you sure you want to delete all tracks?"),
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
}

extension ServiceView {
    enum ServiceType {
        case primary
        case secondary
    }
}
