//
//  TracksTableRow.swift
//  Music Transfer
//
//  Created by panandafog on 27.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct TracksTableRow: View {
    
    var track: SharedTrack
    
    var body: some View {
        HStack {
            Text(track.strArtists() + " – " + track.title)
            
            if let duration = getDuration() {
                Spacer()
                Text(duration)
            }
        }
    }
    
    func getDuration() -> String? {
        guard let duration = track.duration else {
            return nil
        }
        let minutes = String(Int(duration / 60))
        var seconds = String(duration % 60)
        if duration % 60 < 10 {
            seconds = "0" + seconds
        }
        return minutes + ":" + seconds
    }
}

// swiftlint:disable type_name
struct TracksTableRowView_Preview: PreviewProvider {
    static var previews: some View {
        TracksTableRow(track: SharedTrack(id: "1488", serverID: nil, artists: ["Rammstein", "Nietsmmar"], title: "Sonne", duration: 355, servicesData: []))
    }
}
