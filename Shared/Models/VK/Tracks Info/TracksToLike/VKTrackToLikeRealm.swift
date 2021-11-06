//
//  VKTrackToLikeRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import RealmSwift

class VKTrackToLikeRealm: Object {
    @objc dynamic var id = 0
    @objc dynamic var liked = false
    
    @objc dynamic var track: VKSavedItemRealm?
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension VKTrackToLikeRealm {
    var trackToLike: VKTrackToLike {
        VKTrackToLike(
            id: id,
            track: track!.vkSavedItem,
            liked: liked
        )
    }
    
    convenience init(_ trackToLike: VKTrackToLike) {
        self.init()
        
        id = trackToLike.id ?? Self.incrementedPK()
        track = VKSavedItemRealm(trackToLike.track)
        liked = trackToLike.liked
    }
}
