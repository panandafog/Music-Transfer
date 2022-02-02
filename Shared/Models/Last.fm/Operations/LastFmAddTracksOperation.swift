//
//  LastFmAddTracksOperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import Foundation

class LastFmAddTracksOperation: TransferOperation {
    
    var id = NSUUID().uuidString
    
    var searchSuboperaion: LastFmSearchTracksSuboperation
    var likeSuboperation: LastFmLikeTracksSuboperation
    
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
        searchSuboperaion: LastFmSearchTracksSuboperation,
        likeSuboperation: LastFmLikeTracksSuboperation
    ) {
        self.searchSuboperaion = searchSuboperaion
        self.likeSuboperation = likeSuboperation
    }
    
    init(tracksToAdd: [SharedTrack]) {
        searchSuboperaion = LastFmSearchTracksSuboperation(
            started: nil,
            completed: nil,
            tracks: tracksToAdd.map {
                LastFmSearchedTrack(
                    trackToSearch: $0
                )
            }
        )
        
        likeSuboperation = LastFmLikeTracksSuboperation(
            started: nil,
            completed: nil,
            tracksToLike: [],
            notFoundTracks: []
        )
    }
}
