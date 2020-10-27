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
            TextField("", text: .constant(track.title + " – " + track.strArtists()))
            Spacer()
            Text(String(Int(track.durationS / 60)) + ":" + String(track.durationS % 60))
        }
    }
}

struct TracksTableRowView_Preview: PreviewProvider {
    static var previews: some View {
        TracksTableRow(track: SharedTrack(id: "1488", artists: ["Rammstein", "Nietsmmar"], title: "Sonne", durationS: 345))
    }
}
