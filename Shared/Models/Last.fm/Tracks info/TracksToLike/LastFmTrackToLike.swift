//
//  LastFmTrackToLike.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import Foundation

struct LastFmTrackToLike {
    var id = NSUUID().uuidString
    
    var track: LastFmTrackSearchResult.Track
    var liked: Bool
}
