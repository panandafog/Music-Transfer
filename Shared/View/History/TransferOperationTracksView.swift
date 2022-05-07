//
//  TransferOperationTracksView.swift
//  Music Transfer
//
//  Created by panandafog on 28.11.2021.
//

import SwiftUI

struct TransferOperationTracksView: View {
    
    var entryPreview: MTHistoryEntryPreview
    
    @State var remoteOperation: TransferOperation?
    @State var downloadingRemoteOperation: Bool = false
    
    @ObservedObject private var model = TransferManager.shared
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
        .modify {
            switch entryPreview {
            case .entry:
                $0.task {
                    downloadOperationDetails()
                }
            case .operation:
                $0
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
    
    private func downloadOperationDetails() {
        let entry: MTHistoryEntry
        
        switch entryPreview {
        case .entry(let historyEntry):
            entry = historyEntry
        default:
            return
        }
        
        guard !downloadingRemoteOperation else { return }
        downloadingRemoteOperation = true
        
        let resultHandler: ((Result<TransferOperation, Error>) -> Void) = { result in
            self.downloadingRemoteOperation = false
            switch result {
            case .success(let operation):
                self.remoteOperation = operation
            case .failure(let error):
                break
            }
        }
        
        let vkResultHandler: ((Result<VKAddTracksOperationServerModel, Error>) -> Void) = { result in
            switch result {
            case .success(let operation):
                resultHandler(.success(operation.clientModel))
            case .failure(let error):
                resultHandler(.failure(error))
            }
        }
        
        let lastFmResultHandler: ((Result<LastFmAddTracksOperationServerModel, Error>) -> Void) = { result in
            switch result {
            case .success(let operation):
                resultHandler(.success(operation.clientModel))
            case .failure(let error):
                resultHandler(.failure(error))
            }
        }
        
        switch entry.type {
        case .vk:
            model.mtService.getOperation(entry.id, completion: vkResultHandler)
        case .lastFm:
            model.mtService.getOperation(entry.id, completion: lastFmResultHandler)
        }
    }
}
