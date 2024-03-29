//
//  SpotifySearchTracksSuboperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

class SpotifySearchTracksSuboperationRealm: Object {
    
    @objc dynamic var id = ""
    
    @objc dynamic var started: NSDate?
    @objc dynamic var completed: NSDate?
    
    let tracks = List<SpotifySearchedTrackRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifySearchTracksSuboperationRealm {
    var spotifySearchTracksSuboperation: SpotifySearchTracksSuboperation {
        SpotifySearchTracksSuboperation(
            id: id,
            started: started as Date?,
            completed: completed as Date?,
            tracks: tracks.map { $0.searchedTrack }
        )
    }
    
    convenience init(_ spotifySearchTracksSuboperation: SpotifySearchTracksSuboperation) {
        self.init()
        
        id = spotifySearchTracksSuboperation.id
        
        started = spotifySearchTracksSuboperation.started as NSDate?
        completed = spotifySearchTracksSuboperation.completed as NSDate?
        tracks.append(objectsIn: spotifySearchTracksSuboperation.tracks.map { SpotifySearchedTrackRealm($0) })
    }
}
