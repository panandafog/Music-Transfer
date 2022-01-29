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
            TextField("", text: .constant(track.strArtists() + " – " + track.title))
            Spacer()
            
            Text(getDuration())
        }
    }
    
    func getDuration() -> String {
        let minutes = String(Int(track.duration / 60))
        var seconds = String(track.duration % 60)
        if track.duration % 60 < 10 {
            seconds = "0" + seconds
        }
        return minutes + ":" + seconds
    }
}

// swiftlint:disable type_name
struct TracksTableRowView_Preview: PreviewProvider {
    static var previews: some View {
        TracksTableRow(track: SharedTrack(id: "1488", artists: ["Rammstein", "Nietsmmar"], title: "Sonne", duration: 355, servicesData: []))
    }
}
