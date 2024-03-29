//
//  Music_TransferApp.swift
//  Shared
//
//  Created by panandafog on 07.01.2021.
//

import SwiftUI

@main
// swiftlint:disable type_name
struct Music_TransferApp: App {
    // swiftlint:enable type_name
    
    @ObservedObject private var alertsManager = AlertsManager.shared
    
    @State private var selectedView: Int?
    @State private var tst: Int? = 1
    
    var sidebarList: some View {
        let sidebarList = List {
            NavigationLink(destination: TransferView(), tag: 1, selection: $selectedView) {
                Text("Start operation")
            }
            NavigationLink(destination: HistoryView(), tag: 2, selection: $selectedView) {
                Text("History")
            }
        }
            .listStyle(SidebarListStyle())
        
#if os(macOS)
        return sidebarList
            .frame(minWidth: 150, idealWidth: 150, maxWidth: 200, maxHeight: .infinity)
            .padding(.top, 16)
#else
        return sidebarList
            .navigationBarTitle("Music transfer")
#endif
    }
    
    var bigTransferMenu: some View {
        NavigationView {
            sidebarList
            TransferView()
        }
        .onAppear {
            self.selectedView = 1
            //                        let device = UIDevice.current
            //                        if device.model == "iPad" && device.orientation.isLandscape {
            //                            self.selectedView = 1
            //                        }
            //                        if device.model == "iPhone" && device.orientation.isLandscape {
            //                            self.selectedView = 1
            //                        }
        }
    }
    
    var smallTransferMenu: some View {
        TabView {
            NavigationView {
                TransferView()
            }
            .tabItem {
                Label("Transfer", systemImage: "list.dash")
            }
            NavigationView {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "square.and.pencil")
            }
        }
    }
    
    var transferMenu: some View {
#if os(macOS)
        return AnyView(bigTransferMenu)
#else
        if UIDevice.current.model == "iPad" {
            return AnyView(bigTransferMenu)
        } else {
            return AnyView(smallTransferMenu)
        }
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            transferMenu
                .alert(
                    isPresented: Binding<Bool>(
                        get: {
                            alertsManager.alert != nil
                        },
                        set: { presenting in
                            if !presenting {
                                alertsManager.alert = nil
                            }
                        }
                    )
                ) {
                    alertsManager.alert ?? Alert(title: Text(""))
                }
        }
    }
}
