//
//  VKAddTracksOperationServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct VKAddTracksOperationServerModel: Codable {
    let id: Int?
    let started, completed: String?
    let searchSuboperation: VKSearchTracksSuboperationServerModel
    let likeSuboperation: VKLikeTracksSuboperationServerModel
}

extension VKAddTracksOperationServerModel {
    
    var clientModel: VKAddTracksOperation {
        let clientModel = VKAddTracksOperation(
            serverID: id,
            searchSuboperaion: searchSuboperation.clientModel,
            likeSuboperation: likeSuboperation.clientModel
        )
        clientModel.serverID = id
        return clientModel
    }
    
    init(clientModel: VKAddTracksOperation) {
        id = clientModel.serverID
        searchSuboperation = VKSearchTracksSuboperationServerModel(
            clientModel: clientModel.searchSuboperaion
        )
        likeSuboperation = VKLikeTracksSuboperationServerModel(
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
