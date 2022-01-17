//
//  SpotifyTracksPackageToLike.swift
//  Music Transfer
//
//  Created by panandafog on 24.10.2021.
//

import Foundation

struct SpotifyTracksPackageToLike {
    var id = NSUUID().uuidString
    
    var tracks: [SpotifySearchTracks.Item]
    var liked: Bool
}
