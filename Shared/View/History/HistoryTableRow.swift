//
//  HistoryTableRow.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 07.11.2021.
//

import SwiftUI

struct HistoryTableRow: View {
    
    private let defaultString = "unknown"
    private let titleLabelBottomOffset: CGFloat = 10
    private let secondaryLabelsLeadingOffset: CGFloat = 10
    private let secondaryLabelsSectionOffset: CGFloat = 10
    
    var operation: MTHistoryEntryPreview
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(getName())
            Spacer()
                .frame(height: secondaryLabelsLeadingOffset)
            HStack {
                Spacer()
                    .frame(width: secondaryLabelsLeadingOffset)
                VStack(alignment: .leading) {
                    switch operation {
                    case .operation(let transferOperation):
                        Text("tracks count: \(getString(from: transferOperation.tracksCount))")
                        Spacer()
                            .frame(height: secondaryLabelsLeadingOffset)
                    default: Group { }
                    }
                    Text("started: \(getString(from: operation.started))")
                    Text("completed: \(getString(from: operation.completed))")
                }
            }
        }
        .padding([.vertical])
    }
    
    func getName() -> String {
        switch operation {
        case .entry(let mtHistoryEntry):
            switch mtHistoryEntry.type {
            case .lastFm:
                return "Transfer to last.fm"
            case .vk:
                return "Transfer to VK"
            }
        case .operation(let transferOperation):
            if (transferOperation as? SpotifyAddTracksOperation) != nil {
                return "Transfer to Spotify"
            }
            if (transferOperation as? VKAddTracksOperation) != nil {
                return "Transfer to VK"
            }
            if (transferOperation as? LastFmAddTracksOperation) != nil {
                return "Transfer to last.fm"
            }
        }
        return defaultString
    }
    
    func getString(from date: Date?) -> String {
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, h:mm a"
            
            return dateFormatter.string(from: date)
        }
        return defaultString
    }
    
    func getString(from int: Int?) -> String {
        if let int = int {
            return String(int)
        } else {
            return defaultString
        }
    }
}
