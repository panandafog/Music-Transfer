//
//  SpotifySearchTracksSuboperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

class SpotifySearchTracksSuboperationRealm: Object {
    
    @objc dynamic var id = 0
    
    @objc dynamic var started = false
    @objc dynamic var completed = false
    
    let tracks = List<SpotifySearchedTrackRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifySearchTracksSuboperationRealm {
    var spotifySearchTracksSuboperation: SpotifySearchTracksSuboperation {
        SpotifySearchTracksSuboperation(
            id: Int(id),
            started: started,
            completed: completed,
            tracks: tracks.map { $0.searchedTrack }
        )
    }
    
    convenience init(_ spotifySearchTracksSuboperation: SpotifySearchTracksSuboperation) {
        self.init()
        
        if let intID = spotifySearchTracksSuboperation.id {
            id = intID
        } else {
            id = Self.incrementedPK()
        }
        
        started = spotifySearchTracksSuboperation.started
        completed = spotifySearchTracksSuboperation.completed
        tracks.append(objectsIn: spotifySearchTracksSuboperation.tracks.map { SpotifySearchedTrackRealm($0) })
    }
}
