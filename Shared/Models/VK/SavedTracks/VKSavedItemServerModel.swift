//
//  VKSavedItemServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct VKSavedItemServerModel: Codable {
    let id: Int?
    let title, artist: String
    let ownerID, duration: Int
}

extension VKSavedItemServerModel {
    
    var clientModel: VKSavedTracks.Item {
        VKSavedTracks.Item(
            artist: artist,
            serverID: id,
            owner_id: ownerID,
            title: title,
            duration: duration
        )
    }
    
    init(clientModel: VKSavedTracks.Item) {
        id = clientModel.serverID
        artist = clientModel.artist
        ownerID = clientModel.owner_id
        title = clientModel.title
        duration = clientModel.duration
    }
}
