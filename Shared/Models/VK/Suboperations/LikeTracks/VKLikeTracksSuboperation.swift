//
//  VKLikeTracksSuboperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import Foundation

struct VKLikeTracksSuboperation: TransferSuboperation {
    var id = NSUUID().uuidString
    
    var started = false
    var completed = false
    
    var tracksToLike: [VKTrackToLike]
    var notFoundTracks: [SharedTrack]
    var duplicates: [SharedTrack]
}
