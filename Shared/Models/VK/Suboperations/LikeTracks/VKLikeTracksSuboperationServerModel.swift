//
//  VKLikeTracksSuboperationServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct VKLikeTracksSuboperationServerModel: Codable {
    let id: Int?
    let started, completed: String?
    let tracksToLike: [VKTrackToLikeServerModel]
    let notFoundTracks, duplicates: [SharedTrackServerModel]
}

extension VKLikeTracksSuboperationServerModel {
    
    var clientModel: VKLikeTracksSuboperation {
        var started: Date?
        var completed: Date?
        
        if let startedStr = self.started {
            started = DateFormatter.mt.date(from: startedStr)
        }
        if let completedStr = self.started {
            completed = DateFormatter.mt.date(from: completedStr)
        }
        
        return VKLikeTracksSuboperation(
            serverID: id,
            started: started,
            completed: completed,
            tracksToLike: tracksToLike.map { $0.clientModel },
            notFoundTracks: notFoundTracks.map { $0.clientModel },
            duplicates: duplicates.map { $0.clientModel }
        )
    }
    
    init(clientModel: VKLikeTracksSuboperation) {
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
        
        tracksToLike = clientModel.tracksToLike.map { VKTrackToLikeServerModel(clientModel: $0) }
        notFoundTracks = clientModel.notFoundTracks.map { SharedTrackServerModel(clientModel: $0) }
        duplicates = clientModel.duplicates.map { SharedTrackServerModel(clientModel: $0) }
    }
}
