//
//  LastFmSearchedTrackServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct LastFmSearchedTrackServerModel: Codable {
    let id: Int?
    let triedToSearchTracks: Bool
    let trackToSearch: SharedTrackServerModel
    let foundTracks: [LastFmTrackServerModel]
}

extension LastFmSearchedTrackServerModel {
    
    var clientModel: LastFmSearchedTrack {
        LastFmSearchedTrack(
            serverID: id,
            trackToSearch: trackToSearch.clientModel,
            foundTracks: triedToSearchTracks ? foundTracks.map { $0.clientModel } : nil
        )
    }
    
    init(clientModel: LastFmSearchedTrack) {
        id = clientModel.serverID
        triedToSearchTracks = clientModel.foundTracks == nil
        trackToSearch = SharedTrackServerModel(clientModel: clientModel.trackToSearch)
        foundTracks = (clientModel.foundTracks ?? []).map { LastFmTrackServerModel(clientModel: $0) }
    }
}
