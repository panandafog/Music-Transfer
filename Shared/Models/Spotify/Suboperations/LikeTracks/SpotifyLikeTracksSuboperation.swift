//
//  SpotifyLikeTracksSuboperation.swift
//  Music Transfer
//
//  Created by panandafog on 24.10.2021.
//

import Foundation

struct SpotifyLikeTracksSuboperation: TransferSuboperation {
    var id = NSUUID().uuidString
    
    var started: Date?
    var completed: Date?
    
    var trackPackagesToLike: [SpotifyTracksPackageToLike]
    var notFoundTracks: [SharedTrack]
}
