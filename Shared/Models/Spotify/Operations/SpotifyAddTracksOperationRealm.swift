//
//  SpotifyAddTracksOperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 07.11.2021.
//

import Foundation
import RealmSwift

class SpotifyAddTracksOperationRealm: Object {
    
    @objc dynamic var id = ""
    
    @objc dynamic var searchSuboperaion: SpotifySearchTracksSuboperationRealm?
    @objc dynamic var likeSuboperation: SpotifyLikeTracksSuboperationRealm?
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifyAddTracksOperationRealm {
    var spotifyAddTracksOperation: SpotifyAddTracksOperation {
        SpotifyAddTracksOperation(
            searchSuboperaion: searchSuboperaion!.spotifySearchTracksSuboperation,
            likeSuboperation: likeSuboperation!.spotifyLikeTracksSuboperation
        )
    }
    
    convenience init(_ spotifyAddTracksOperation: SpotifyAddTracksOperation) {
        self.init()
        
        id = spotifyAddTracksOperation.id
        
        searchSuboperaion = SpotifySearchTracksSuboperationRealm(
            spotifyAddTracksOperation.searchSuboperaion
        )
        likeSuboperation = SpotifyLikeTracksSuboperationRealm(
            spotifyAddTracksOperation.likeSuboperation
        )
    }
}
