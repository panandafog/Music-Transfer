//
//  LastFmLikeTracksSuboperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import Foundation
import RealmSwift

class LastFmLikeTracksSuboperationRealm: Object {
    
    @objc dynamic var id = ""
    
    @objc dynamic var started: NSDate?
    @objc dynamic var completed: NSDate?
    
    let tracksToLike = List<LastFmTrackRealm>()
    let notFoundTracks = List<SharedTrackRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension LastFmLikeTracksSuboperationRealm {
    var lastFmLikeTracksSuboperation: LastFmLikeTracksSuboperation {
        LastFmLikeTracksSuboperation(
            id: id,
            started: started as Date?,
            completed: completed as Date?,
            tracksToLike: tracksToLike.map { $0.lastFmTrack },
            notFoundTracks: notFoundTracks.map { $0.sharedTrack }
        )
    }
    
    convenience init(_ lastFmLikeTracksSuboperation: LastFmLikeTracksSuboperation) {
        self.init()
        
        id = lastFmLikeTracksSuboperation.id
        
        started = lastFmLikeTracksSuboperation.started as NSDate?
        completed = lastFmLikeTracksSuboperation.completed as NSDate?
        
        tracksToLike.append(objectsIn: lastFmLikeTracksSuboperation.tracksToLike.map { LastFmTrackRealm($0) })
        notFoundTracks.append(objectsIn: lastFmLikeTracksSuboperation.notFoundTracks.map { SharedTrackRealm($0) })
    }
}
