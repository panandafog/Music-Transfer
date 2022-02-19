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
    
    var actionsEnabled: Bool {
        service.isAuthorised || service.refreshing || model.operationInProgress
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
                .disabled(!actionsEnabled)
        )
    }
    
    var viewSavedButton: some View {
        AnyView(
            Button("View saved tracks") {
                self.tracksTableNavigationLinkIsActive = true
            }
                .disabled(!actionsEnabled)
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
                .disabled(!actionsEnabled)
        )
    }
    
    var logOutButton: some View {
        AnyView(
            Button(action: {
                service.logOut()
            }, label: {
                Text("Log out")
            })
                .disabled(!actionsEnabled)
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
    
    var authorizationButton: some View {
        AnyView(
            Button(action: {
                var service = service
                service.showingAuthorization = true
            }, label: {
                Text("Authorize")
            })
            #if !os(macOS)
                .padding(10)
                .background(Color.background)
                .cornerRadius(10)
            #endif
                .sheet(isPresented: $model.services[selection].showingAuthorization) {
                    AuthorizationView(service: $model.services[selection])
                }
        )
    }
    
    var getTracksButton: some View {
        AnyView(
            Button(action: {
                DispatchQueue.global(qos: .background).async {
                    service.getSavedTracks()
                }
            }, label: {
                Text("Get tracks")
#if !os(macOS)
                    .foregroundColor(.background)
#endif
            })
            #if !os(macOS)
                .padding(10)
                .background(Color.accentColor)
                .cornerRadius(10)
            #endif
        )
    }
    
    var toolsView: some View {
        AnyView(
            HStack {
                refreshButton
#if !os(macOS)
                viewSavedButton
#endif
                deleteAllButton
                logOutButton
            }
        )
    }
    
    var debugView: some View {
        HStack {
            Text(String(service.gotTracks))
            Text(String(service.refreshing))
            Text(String(model.operationInProgress))
            Text(String(model.progressActive))
        }
    }
    
    var getTracksView: some View {
        wrapInPreview(AnyView(getTracksButton))
    }
    
    var refreshingView: some View {
        wrapInPreview(AnyView(ProgressView()))
    }
    
    var tracksPreview: some View {
        if service.refreshing {
#if os(macOS)
            return AnyView(ProgressView())
#else
            return AnyView(refreshingView)
#endif
        } else if !service.isAuthorised {
            return AnyView(authorizationButton)
        } else if !service.gotTracks {
#if os(macOS)
            return AnyView(getTracksButton)
#else
            return AnyView(getTracksView)
#endif
        } else {
#if os(macOS)
            return AnyView(
                VStack {
                    toolsView
                    TracksTable(tracks: .init(get: {
                        service.savedTracks
                    }, set: { _ in }), name: "Saved tracks:")
                }
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
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                if service.gotTracks && !service.refreshing && !service.savedTracks.isEmpty {
                                    tracksTableNavigationLinkIsActive = true
                                }
                            }
                    )
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
            tracksPreview
#if os(macOS)
            Spacer()
#endif
        }
        .padding(20)
#if !os(macOS)
        .background(Color.secondaryBackground)
#endif
#if !os(macOS)
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
                .hidden()
        )
#endif
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
    
    func wrapInPreview(_ view: AnyView) -> some View {
        AnyView(
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    view
                    Spacer()
                }
                Spacer()
            }
                .background(Color.background)
                .cornerRadius(10)
        )
    }
}

extension ServiceView {
    enum ServiceType {
        case primary
        case secondary
    }
}
