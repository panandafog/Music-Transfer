//
//  LastFmAddTracksOperationServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct LastFmAddTracksOperationServerModel: Codable {
    let id: Int?
    let started, completed: String?
    let searchSuboperation: LastFmSearchTracksSuboperationServerModel
    let likeSuboperation: LastFmLikeTracksSuboperationServerModel
}

extension LastFmAddTracksOperationServerModel {
    
    var clientModel: LastFmAddTracksOperation {
        let clientModel = LastFmAddTracksOperation(
            serverID: id,
            searchSuboperaion: searchSuboperation.clientModel,
            likeSuboperation: likeSuboperation.clientModel
        )
        clientModel.serverID = id
        return clientModel
    }
    
    init(clientModel: LastFmAddTracksOperation) {
        id = clientModel.serverID
        searchSuboperation = LastFmSearchTracksSuboperationServerModel(
            clientModel: clientModel.searchSuboperaion
        )
        likeSuboperation = LastFmLikeTracksSuboperationServerModel(
            clientModel: clientModel.likeSuboperation
        )
        
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
    }
}
