//
//  HistoryTableRow.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 07.11.2021.
//

import SwiftUI

struct HistoryTableRow: View {
    
    private let defaultString = "..."
    private let titleLabelBottomOffset: CGFloat = 10
    private let secondaryLabelsLeadingOffset: CGFloat = 10
    private let secondaryLabelsSectionOffset: CGFloat = 10
    
    var operation: TransferOperation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(getName())
            Spacer()
                .frame(height: secondaryLabelsLeadingOffset)
            HStack {
                Spacer()
                    .frame(width: secondaryLabelsLeadingOffset)
                VStack(alignment: .leading) {
                    Text("tracks count: \(getString(from: operation.tracksCount))")
                    Spacer()
                        .frame(height: secondaryLabelsLeadingOffset)
                    Text("started: \(getString(from: operation.started))")
                    Text("completed: \(getString(from: operation.completed))")
                }
            }
        }
        .padding([.vertical])
    }
    
    func getName() -> String {
        if (operation as? SpotifyAddTracksOperation) != nil {
            return "Transfer to Spotify"
        }
        if (operation as? VKAddTracksOperation) != nil {
            return "Transfer to VK"
        }
        return defaultString
    }
    
    func getString(from date: Date?) -> String {
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YY, MMM d, hh:mm"
            
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
