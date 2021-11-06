//
//  SpotifyAddTracksOperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 06.11.2021.
//

import Foundation

class SpotifyAddTracksOperation: TransferOperation {
    var id = NSUUID().uuidString
    
    var searchSuboperaion: SpotifySearchTracksSuboperation
    var likeSuboperation: SpotifyLikeTracksSuboperation
    
    var suboperations: [TransferSuboperation] {
        [searchSuboperaion, likeSuboperation]
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
            started: false,
            completed: false,
            tracks: tracksToAdd.map {
                SpotifySearchedTrack(
                    trackToSearch: $0,
                    foundTracks: nil
                )
            }
        )
        
        likeSuboperation = SpotifyLikeTracksSuboperation(
            started: false,
            completed: false,
            trackPackagesToLike: [],
            notFoundTracks: []
        )
    }
}
