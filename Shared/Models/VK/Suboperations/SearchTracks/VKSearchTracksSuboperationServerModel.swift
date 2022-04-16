//
//  VKSearchTracksSuboperationServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct VKSearchTracksSuboperationServerModel: Codable {
    let id: Int?
    let started, completed: String?
    let searchedTracks: [VKSearchedTrackServerModel]
}

extension VKSearchTracksSuboperationServerModel {
    
    var clientModel: VKSearchTracksSuboperation {
        var started: Date?
        var completed: Date?
        
        if let startedStr = self.started {
            started = DateFormatter.mt.date(from: startedStr)
        }
        if let completedStr = self.started {
            completed = DateFormatter.mt.date(from: completedStr)
        }
        
        return VKSearchTracksSuboperation(
            serverID: id,
            started: started,
            completed: completed,
            tracks: searchedTracks.map { $0.clientModel }
        )
    }
    
    init(clientModel: VKSearchTracksSuboperation) {
        id = clientModel.serverID
        
        if let clientModelStarted = clientModel.started {
            started = DateFormatter.mt.string(from: clientModelStarted)
        } else {
            started = nil
        }
        if let clientModelCompleted = clientModel.completed {
            completed = DateFormatter.mt.string(from: clientModelCompleted)
        } else {
            completed = nil
        }
        
        searchedTracks = clientModel.tracks.map { VKSearchedTrackServerModel(clientModel: $0) }
    }
}
