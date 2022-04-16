//
//  VKAddTracksOperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 07.11.2021.
//

// swiftlint:disable force_unwrapping

import Foundation
import RealmSwift

class VKAddTracksOperationRealm: Object {
    
    @objc dynamic var id = ""
    let serverID = RealmProperty<Int?>()
    
    @objc dynamic var searchSuboperaion: VKSearchTracksSuboperationRealm?
    @objc dynamic var likeSuboperation: VKLikeTracksSuboperationRealm?
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension VKAddTracksOperationRealm {
    var vkAddTracksOperation: VKAddTracksOperation {
        VKAddTracksOperation(
            id: id,
            serverID: serverID.value,
            searchSuboperaion: searchSuboperaion!.vkSearchTracksSuboperation,
            likeSuboperation: likeSuboperation!.vkLikeTracksSuboperation
        )
    }
    
    convenience init(_ vkAddTracksOperation: VKAddTracksOperation) {
        self.init()
        
        id = vkAddTracksOperation.id
        serverID.value = vkAddTracksOperation.serverID
        
        searchSuboperaion = VKSearchTracksSuboperationRealm(
            vkAddTracksOperation.searchSuboperaion
        )
        likeSuboperation = VKLikeTracksSuboperationRealm(
            vkAddTracksOperation.likeSuboperation
        )
    }
}
