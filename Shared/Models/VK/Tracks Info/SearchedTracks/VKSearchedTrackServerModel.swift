//
//  VKSearchedTrackServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct VKSearchedTrackServerModel: Codable {
    let id: Int?
    let triedToSearchTracks: Bool
    let trackToSearch: SharedTrackServerModel
    let foundTracks: [VKSavedItemServerModel]
}

extension VKSearchedTrackServerModel {
    
    var clientModel: VKSearchedTrack {
        VKSearchedTrack(
            serverID: id,
            trackToSearch: trackToSearch.clientModel,
            foundTracks: triedToSearchTracks ? foundTracks.map { $0.clientModel } : nil
        )
    }
    
    init(clientModel: VKSearchedTrack) {
        id = clientModel.serverID
        triedToSearchTracks = clientModel.foundTracks != nil
        trackToSearch = SharedTrackServerModel(clientModel: clientModel.trackToSearch)
        foundTracks = clientModel.foundTracks?.map {
            VKSavedItemServerModel(clientModel: $0)
        } ?? []
    }
}
