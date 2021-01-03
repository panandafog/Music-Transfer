//
//  TracksTable.swift
//  Music Transfer
//
//  Created by panandafog on 27.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct TracksTable: View {
    
    @Binding var tracks: [SharedTrack]
    let name: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
            Text(name)
                .font(.body)
            ZStack {
                List(tracks) { track in
                    TracksTableRow(track: track)
                }
            }
        })
        .padding()
    }
}
