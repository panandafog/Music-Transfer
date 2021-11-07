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
        VStack(alignment: .leading, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
            HStack {
                Text("History")
                    .font(.body)
                Spacer()
                Text("count: \(model.operationsHistory.count)")
            }
            ZStack {
                List(model.operationsHistory, id: \.id) { operation in
                    HistoryTableRow(operation: operation)
                }
            }
        })
            .padding()
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
