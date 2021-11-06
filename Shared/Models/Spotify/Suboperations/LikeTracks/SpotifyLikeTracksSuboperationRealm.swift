//
//  SpotifyLikeTracksSuboperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

class SpotifyLikeTracksSuboperationRealm: Object {
    
    @objc dynamic var id = 0
    
    @objc dynamic var started = false
    @objc dynamic var completed = false
    
    let trackPackagesToLike = List<SpotifyTracksPackageToLikeRealm>()
    let notFoundTracks = List<SharedTrackRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifyLikeTracksSuboperationRealm {
    var spotifyLikeTracksSuboperation: SpotifyLikeTracksSuboperation {
        SpotifyLikeTracksSuboperation(
            id: Int(id),
            started: started,
            completed: completed,
            trackPackagesToLike: trackPackagesToLike.map { $0.tracksPackage },
            notFoundTracks: notFoundTracks.map { $0.sharedTrack }
        )
    }
    
    convenience init(_ spotifyLikeTracksSuboperation: SpotifyLikeTracksSuboperation) {
        self.init()
        
        if let intID = spotifyLikeTracksSuboperation.id {
            id = intID
        } else {
            id = Self.incrementedPK()
        }
        
        started = spotifyLikeTracksSuboperation.started
        completed = spotifyLikeTracksSuboperation.completed
        
        trackPackagesToLike.append(objectsIn: spotifyLikeTracksSuboperation.trackPackagesToLike.map { SpotifyTracksPackageToLikeRealm($0) })
        notFoundTracks.append(objectsIn: spotifyLikeTracksSuboperation.notFoundTracks.map { SharedTrackRealm($0) })
    }
}