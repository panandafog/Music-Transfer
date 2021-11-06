//
//  VKAddTracksOperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 07.11.2021.
//

import Foundation
import RealmSwift

class VKAddTracksOperationRealm: Object {
    
    @objc dynamic var id = ""
    
    @objc dynamic var searchSuboperaion: VKSearchTracksSuboperationRealm?
    @objc dynamic var likeSuboperation: VKLikeTracksSuboperationRealm?
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension VKAddTracksOperationRealm {
    var vkAddTracksOperation: VKAddTracksOperation {
        VKAddTracksOperation(
            searchSuboperaion: searchSuboperaion!.vkSearchTracksSuboperation,
            likeSuboperation: likeSuboperation!.vkLikeTracksSuboperation
        )
    }
    
    convenience init(_ vkAddTracksOperation: VKAddTracksOperation) {
        self.init()
        
        id = vkAddTracksOperation.id
        
        searchSuboperaion = VKSearchTracksSuboperationRealm(
            vkAddTracksOperation.searchSuboperaion
        )
        likeSuboperation = VKLikeTracksSuboperationRealm(
            vkAddTracksOperation.likeSuboperation
        )
    }
}
