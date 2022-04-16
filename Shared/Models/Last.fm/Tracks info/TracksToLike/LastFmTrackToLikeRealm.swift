//
//  LastFmTrackToLikeRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import RealmSwift

class LastFmTrackToLikeRealm: Object {
    @objc dynamic var id = ""
    let serverID = RealmProperty<Int?>()
    
    @objc dynamic var liked = false
    
    @objc dynamic var track: LastFmTrackRealm?
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension LastFmTrackToLikeRealm {
    var trackToLike: LastFmTrackToLike {
        LastFmTrackToLike(
            id: id,
            serverID: serverID.value,
            track: track!.lastFmTrack,
            liked: liked
        )
    }
    
    convenience init(_ track: LastFmTrackToLike) {
        self.init()
        
        id = track.id
        serverID.value = track.serverID
        self.track = LastFmTrackRealm(track.track)
        liked = track.liked
    }
}
