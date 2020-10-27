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
        List(manager.facades[selectionFrom].savedTracks) { track in
            TracksTableRow(track: track)
        }
    }
}
