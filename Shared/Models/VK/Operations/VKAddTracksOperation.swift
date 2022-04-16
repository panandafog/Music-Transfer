//
//  VKAddTracksOperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 07.11.2021.
//

import Foundation

class VKAddTracksOperation: TransferOperation {
    
    var id = NSUUID().uuidString
    var serverID: Int?
    
    var searchSuboperaion: VKSearchTracksSuboperation
    var likeSuboperation: VKLikeTracksSuboperation
    
    var suboperations: [TransferSuboperation] {
        [searchSuboperaion, likeSuboperation]
    }
    
    var tracksCount: Int? {
        guard likeSuboperation.completed != nil else {
            return nil
        }
  
        return likeSuboperation.tracksToLike.count
    }
    
    init(
        id: String = NSUUID().uuidString,
        serverID: Int?,
        searchSuboperaion: VKSearchTracksSuboperation,
        likeSuboperation: VKLikeTracksSuboperation
    ) {
        self.id = id
        self.serverID = serverID
        self.searchSuboperaion = searchSuboperaion
        self.likeSuboperation = likeSuboperation
    }
    
    init(tracksToAdd: [SharedTrack]) {
        searchSuboperaion = VKSearchTracksSuboperation(
            started: nil,
            completed: nil,
            tracks: tracksToAdd.map {
                VKSearchedTrack(
                    trackToSearch: $0,
                    foundTracks: nil
                )
            }
        )
        
        likeSuboperation = VKLikeTracksSuboperation(
            started: nil,
            completed: nil,
            tracksToLike: [],
            notFoundTracks: [],
            duplicates: []
        )
    }
}
