//
//  HistoryView.swift
//  Music Transfer
//
//  Created by panandafog on 24.01.2021.
//

import SwiftUI

struct HistoryView: View {
    
    @ObservedObject private var model = TransferManager.shared
    
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
    
    var listView: some View {
        List(model.operationsHistory, id: \.id) { operation in
            NavigationLink(
                destination: TransferOperationTracksView(operation: operation)
            ) {
                HistoryTableRow(operation: operation)
            }
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
