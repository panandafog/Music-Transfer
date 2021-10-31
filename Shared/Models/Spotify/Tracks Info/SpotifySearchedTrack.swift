//
//  SpotifySearchedTrack.swift
//  Music Transfer
//
//  Created by panandafog on 24.10.2021.
//

import Foundation

struct SpotifySearchedTrack {
    var id: Int?
    
    var trackToSearch: SharedTrack
    var foundTracks: [SpotifySearchTracks.Item]?
}
