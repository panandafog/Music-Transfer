//
//  LastFmTrackToLikeServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct LastFmTrackToLikeServerModel: Codable {
    let id: Int?
    let liked: Bool
    let track: LastFmTrackServerModel
}

extension LastFmTrackToLikeServerModel {
    
    var clientModel: LastFmTrackToLike {
        LastFmTrackToLike(
            serverID: id,
            track: track.clientModel,
            liked: liked
        )
    }
    
    init(clientModel: LastFmTrackToLike) {
        id = clientModel.serverID
        liked = clientModel.liked
        track = LastFmTrackServerModel(clientModel: clientModel.track)
    }
}
