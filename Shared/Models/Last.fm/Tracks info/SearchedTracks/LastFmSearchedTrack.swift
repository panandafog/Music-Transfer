//
//  LastFmSearchedTrack.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import Foundation

struct LastFmSearchedTrack {
    var id = NSUUID().uuidString
    
    var trackToSearch: SharedTrack
    var foundTracks: [LastFmTrackSearchResult.Track]?
}
