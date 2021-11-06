//
//  SpotifyLikeTracksSuboperation.swift
//  Music Transfer
//
//  Created by panandafog on 24.10.2021.
//

import Foundation

struct SpotifyLikeTracksSuboperation: TransferSuboperation {
    var id: Int?
    
    var started = false
    var completed = false
    
    var trackPackagesToLike: [SpotifyTracksPackageToLike]
    var notFoundTracks: [SharedTrack]
}
