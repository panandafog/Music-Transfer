//
//  LastFmSearchTracksSuboperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import Foundation

struct LastFmSearchTracksSuboperation: TransferSuboperation {
    var id = NSUUID().uuidString
    var serverID: Int?
    
    var started: Date?
    var completed: Date?
    
    var tracks: [LastFmSearchedTrack]
}
