//
//  LastFmTrackToLike.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import Foundation

struct LastFmTrackToLike {
    var id = NSUUID().uuidString
    var serverID: Int?
    
    var track: LastFmTrackSearchResult.Track
    var liked: Bool
}
