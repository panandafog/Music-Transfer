//
//  SpotifyAddTracksOperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 06.11.2021.
//

import Foundation

class SpotifyAddTracksOperation: TransferOperation {
    
    var id = NSUUID().uuidString
    var serverID: Int?
    
    var searchSuboperaion: SpotifySearchTracksSuboperation
    var likeSuboperation: SpotifyLikeTracksSuboperation
    
    var suboperations: [TransferSuboperation] {
        [searchSuboperaion, likeSuboperation]
    }
    
    var tracksCount: Int? {
        guard likeSuboperation.completed != nil else {
            return nil
        }
        
        var count = 0
        likeSuboperation.trackPackagesToLike.forEach {
            count += $0.tracks.count
        }
        return count
    }
    
    init(
        searchSuboperaion: SpotifySearchTracksSuboperation,
        likeSuboperation: SpotifyLikeTracksSuboperation
    ) {
        self.searchSuboperaion = searchSuboperaion
        self.likeSuboperation = likeSuboperation
    }
    
    init(tracksToAdd: [SharedTrack]) {
        searchSuboperaion = SpotifySearchTracksSuboperation(
            started: nil,
            completed: nil,
            tracks: tracksToAdd.map {
                SpotifySearchedTrack(
                    trackToSearch: $0,
                    foundTracks: nil
                )
            }
        )
        
        likeSuboperation = SpotifyLikeTracksSuboperation(
            started: nil,
            completed: nil,
            trackPackagesToLike: [],
            notFoundTracks: []
        )
    }
}
