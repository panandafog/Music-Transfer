//
//  LastFmLikeTracksSuboperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import Foundation

struct LastFmLikeTracksSuboperation: TransferSuboperation {
    
    var id = NSUUID().uuidString
    
    var started: Date?
    var completed: Date?
    
    var tracksToLike: [LastFmTrackSearchResult.Track]
    var notFoundTracks: [SharedTrack]
}
