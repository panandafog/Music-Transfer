//
//  LastFmTrackToLikeRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import RealmSwift

class LastFmTrackToLikeRealm: Object {
    @objc dynamic var id = ""
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
            track: track!.lastFmTrack,
            liked: liked
        )
    }
    
    convenience init(_ track: LastFmTrackToLike) {
        self.init()
        
        id = track.id
        self.track = LastFmTrackRealm(track.track)
        liked = track.liked
    }
}
