//
//  LastFmSearchTracksSuboperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import Foundation
import RealmSwift

class LastFmSearchTracksSuboperationRealm: Object {
    
    @objc dynamic var id = ""
    
    @objc dynamic var started: NSDate?
    @objc dynamic var completed: NSDate?
    
    let tracks = List<LastFmSearchedTrackRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension LastFmSearchTracksSuboperationRealm {
    var lastFmSearchTracksSuboperation: LastFmSearchTracksSuboperation {
        LastFmSearchTracksSuboperation(
            id: id,
            started: started as Date?,
            completed: completed as Date?,
            tracks: tracks.map { $0.searchedTrack }
        )
    }
    
    convenience init(_ lastFmSearchTracksSuboperation: LastFmSearchTracksSuboperation) {
        self.init()
        
        id = lastFmSearchTracksSuboperation.id
        
        started = lastFmSearchTracksSuboperation.started as NSDate?
        completed = lastFmSearchTracksSuboperation.completed as NSDate?
        tracks.append(objectsIn: lastFmSearchTracksSuboperation.tracks.map { LastFmSearchedTrackRealm($0) })
    }
}
