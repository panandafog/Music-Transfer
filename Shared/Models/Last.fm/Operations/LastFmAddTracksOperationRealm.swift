//
//  LastFmAddTracksOperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

// swiftlint:disable force_unwrapping

import Foundation
import RealmSwift

class LastFmAddTracksOperationRealm: Object {
    
    @objc dynamic var id = ""
    
    @objc dynamic var searchSuboperation: LastFmSearchTracksSuboperationRealm?
    @objc dynamic var likeSuboperation: LastFmLikeTracksSuboperationRealm?
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension LastFmAddTracksOperationRealm {
    
    var lastFmAddTracksOperation: LastFmAddTracksOperation {
        LastFmAddTracksOperation(
            searchSuboperaion: searchSuboperation!.lastFmSearchTracksSuboperation,
            likeSuboperation: likeSuboperation!.lastFmLikeTracksSuboperation
        )
    }
    
    convenience init(_ lastFmAddTracksOperation: LastFmAddTracksOperation) {
        self.init()
        
        id = lastFmAddTracksOperation.id
        
        searchSuboperation = LastFmSearchTracksSuboperationRealm(
            lastFmAddTracksOperation.searchSuboperaion
        )
        likeSuboperation = LastFmLikeTracksSuboperationRealm(
            lastFmAddTracksOperation.likeSuboperation
        )
    }
}
