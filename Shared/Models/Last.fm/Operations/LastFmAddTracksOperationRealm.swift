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
    let serverID = RealmProperty<Int?>()
    
    @objc dynamic var searchSuboperation: LastFmSearchTracksSuboperationRealm?
    @objc dynamic var likeSuboperation: LastFmLikeTracksSuboperationRealm?
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension LastFmAddTracksOperationRealm {
    
    var lastFmAddTracksOperation: LastFmAddTracksOperation {
        LastFmAddTracksOperation(
            id: id,
            serverID: serverID.value,
            searchSuboperaion: searchSuboperation!.lastFmSearchTracksSuboperation,
            likeSuboperation: likeSuboperation!.lastFmLikeTracksSuboperation
        )
    }
    
    convenience init(_ lastFmAddTracksOperation: LastFmAddTracksOperation) {
        self.init()
        
        id = lastFmAddTracksOperation.id
        serverID.value = lastFmAddTracksOperation.serverID
        
        searchSuboperation = LastFmSearchTracksSuboperationRealm(
            lastFmAddTracksOperation.searchSuboperaion
        )
        likeSuboperation = LastFmLikeTracksSuboperationRealm(
            lastFmAddTracksOperation.likeSuboperation
        )
    }
}
