//
//  Music_TransferApp.swift
//  Shared
//
//  Created by panandafog on 07.01.2021.
//

import SwiftUI

@main
struct Music_TransferApp: App {
    
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
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                sidebarList
                TransferView()
            }
            .onAppear {
#if os(macOS)
                self.selectedView = 1
#else
                let device = UIDevice.current
                if device.model == "iPad" && device.orientation.isLandscape {
                    self.selectedView = 1
                }
                if device.model == "iPhone" && device.orientation.isLandscape {
                    self.selectedView = 1
                }
#endif
            }
        }
    }
}
