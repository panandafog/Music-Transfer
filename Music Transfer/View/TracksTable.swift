//
//  TracksTable.swift
//  Music Transfer
//
//  Created by panandafog on 27.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct TracksTable: View {
    
    @Binding var selectionFrom: Int
    @Binding var selectionTo: Int
    @ObservedObject var manager: APIManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
            Text("Saved tracks:")
                .font(.body)
            ZStack {
                List(manager.facades[selectionFrom].savedTracks) { track in
                    TracksTableRow(track: track)
                }
                .padding([.top, .horizontal])
            }
        })
        .padding([.bottom, .horizontal])
    }
}
