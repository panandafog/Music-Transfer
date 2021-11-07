//
//  HistoryTableRow.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 07.11.2021.
//

import SwiftUI

struct HistoryTableRow: View {
    
    var operation: TransferOperation
    
    func getName() -> String {
        if ((operation as? SpotifyAddTracksOperation) != nil) {
            return "Transfer to Spotify"
        }
        if ((operation as? VKAddTracksOperation) != nil) {
            return "Transfer to VK"
        }
        return "..."
    }
    
    var body: some View {
        HStack {
            Text(getName())
        }
    }
}
