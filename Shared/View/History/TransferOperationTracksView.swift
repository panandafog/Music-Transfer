//
//  TransferOperationTracksView.swift
//  Music Transfer
//
//  Created by panandafog on 28.11.2021.
//

import SwiftUI

struct TransferOperationTracksView: View {
    var operation: TransferOperation
    @State private var selectedItem: Int = 0
    
    var body: some View {
        
        List(getTracks(categoryIndex: selectedItem)) { track in
            TracksTableRow(track: track)
        }
        .navigationTitle("Operation results")
        .modify {
#if os(macOS)
            $0
                .padding([.top], defaultToolbarPadding)
#else
            $0
#endif
        }
        .toolbar {
            ToolbarItem {
                Picker("Choose", selection: $selectedItem) {
                    ForEach(TracksInfoCategory.allCases, id: \.rawValue) { category in
                        Text(category.displayableName).tag(category.rawValue)
                    }
                }
            }
        }
    }
    
    private func getTracks(categoryIndex: Int) -> [SharedTrack] {
        var tracks = [SharedTrack]()
        if let category = TracksInfoCategory(rawValue: selectedItem) {
            tracks = operation.getTracks(category)
        }
        return tracks
    }
}
