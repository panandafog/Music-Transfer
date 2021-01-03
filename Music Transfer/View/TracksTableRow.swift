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
    
    func getDuration() -> String {
        let minutes = String(Int(track.durationS / 60))
        var seconds = String(track.durationS % 60)
        if track.durationS % 60 < 10 {
            seconds = "0" + seconds
        }
        return minutes + ":" + seconds
    }
    
    var body: some View {
        HStack {
            TextField("", text: .constant(track.strArtists() + " – " + track.title))
                .padding(.leading)
            Spacer()
        
            Text(getDuration())
                .padding(.trailing)
        }
    }
}

struct TracksTableRowView_Preview: PreviewProvider {
    static var previews: some View {
        TracksTableRow(track: SharedTrack(id: "1488", artists: ["Rammstein", "Nietsmmar"], title: "Sonne", durationS: 355))
    }
}
