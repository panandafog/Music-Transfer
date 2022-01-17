//
//  SpotifySearchTracksSuboperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation

struct SpotifySearchTracksSuboperation: TransferSuboperation {
    var id = NSUUID().uuidString
    
    var started: Date?
    var completed: Date?
    
    var tracks: [SpotifySearchedTrack]
}
