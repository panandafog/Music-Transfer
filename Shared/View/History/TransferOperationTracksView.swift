//
//  TransferOperationTracksView.swift
//  Music Transfer
//
//  Created by panandafog on 28.11.2021.
//

import SwiftUI

struct TransferOperationTracksView: View {
    var entryPreview: MTHistoryEntryPreview
    var remoteOperation: TransferOperation?
    
    @State private var selectedItem: Int = 0
    
    var mainView: some View {
        switch entryPreview {
        case .entry(let mtHistoryEntry):
            if let remoteOperation = remoteOperation {
                return AnyView(listOfTracks(operation: remoteOperation))
            } else {
                return AnyView(ProgressView())
            }
        case .operation(let transferOperation):
            return AnyView(listOfTracks(operation: transferOperation))
        }
    }
    
    func listOfTracks(operation: TransferOperation) -> some View {
        List(getTracks(categoryIndex: selectedItem, operation: operation)) { track in
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
    }
    
    var body: some View {
        
        mainView
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
    
    private func getTracks(categoryIndex: Int, operation: TransferOperation) -> [SharedTrack] {
        var tracks = [SharedTrack]()
        if let category = TracksInfoCategory(rawValue: selectedItem) {
            tracks = operation.getTracks(category)
        }
        return tracks
    }
}
