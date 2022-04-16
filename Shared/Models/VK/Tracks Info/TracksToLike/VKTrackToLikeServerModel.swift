//
//  VKTrackToLikeServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct VKTrackToLikeServerModel: Codable {
    let id: Int?
    let liked: Bool
    let savedItem: VKSavedItemServerModel
}

extension VKTrackToLikeServerModel {
    
    var clientModel: VKTrackToLike {
        VKTrackToLike(
            serverID: id,
            track: savedItem.clientModel,
            liked: liked
        )
    }
    
    init(clientModel: VKTrackToLike) {
        id = clientModel.serverID
        liked = clientModel.liked
        savedItem = VKSavedItemServerModel(clientModel: clientModel.track)
    }
}
