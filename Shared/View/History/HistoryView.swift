//
//  HistoryView.swift
//  Music Transfer
//
//  Created by panandafog on 24.01.2021.
//

import SwiftUI

struct HistoryView: View {
    
    @ObservedObject private var model = TransferManager.shared
    
    var progressView: some View {
        if model.updatingHistoryInProgress {
            return AnyView(Text("Updating history..."))
        } else if model.uploadingHistoryInProgress {
            return AnyView(Text("Uploading history..."))
        } else {
            return AnyView(Button(
                action: {
                    model.updateRemoteOperationsHistory()
                },
                label: {
                    Text("Update history")
                }
            ))
        }
    }
    
    var listView: some View {
        VStack {
            if model.mtService.isAuthorised {
                List(model.remoteOperationsHistory, id: \.id) { historyEntry in
                    NavigationLink(
                        destination: TransferOperationTracksView(entryPreview: .entry(historyEntry))
                    ) {
                        HistoryTableRow(operation: .entry(historyEntry))
                    }
                }
            } else {
                List(model.savedOperationsHistory, id: \.id) { operation in
                    NavigationLink(
                        destination: TransferOperationTracksView(entryPreview: .operation(operation))
                    ) {
                        HistoryTableRow(operation: .operation(operation))
                    }
                }
            }
            if !model.mtService.isAuthorised {
                authorizationRequestView
            } else {
                progressView
            }
        }
        .sheet(isPresented: $model.mtService.showingAuthorization) {
            AuthorizationView(service:
                    .init(
                        get: {
                            model.mtService
                        },
                        set: { service in
                            if let mtService = service as? MTService {
                                model.mtService = mtService
                            }
                        }
                    )
            )
        }
        .sheet(isPresented: $model.mtService.showingSignUp) {
            CreateAccountView(service:
                    .init(
                        get: {
                            model.mtService
                        },
                        set: { service in
                            if let mtService = service as? MTService {
                                model.mtService = mtService
                            }
                        }
                    )
            )
        }
        .sheet(isPresented: $model.mtService.showingEmailConfirmation) {
            AccountConfirmationView(service: .init(
                get: {
                    model.mtService
                },
                set: { service in
                    if let mtService = service as? MTService {
                        model.mtService = mtService
                    }
                }
            ))
        }
    }
    
    var authorizationRequestView: some View {
        ZStack {
            Color.orange
            Text("Log in Music Transfer to upload history")
                .foregroundColor(.white)
        }
        .frame(height: 40)
        .gesture(
            TapGesture()
                .onEnded { _ in
                    model.mtService.showingAuthorization.toggle()
                    print(model.mtService.showingAuthorization)
                }
        )
    }
    
    var body: some View {
#if os(macOS)
        NavigationView {
            listView
        }
        .navigationTitle("History")
        .padding([.top], defaultToolbarPadding)
#else
        listView
            .navigationTitle("History")
            .padding([.top], defaultToolbarPadding)
#endif
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
