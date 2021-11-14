//
//  SpotifyLikeTracksSuboperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

class SpotifyLikeTracksSuboperationRealm: Object {
    
    @objc dynamic var id = ""
    
    @objc dynamic var started: NSDate?
    @objc dynamic var completed: NSDate?
    
    let trackPackagesToLike = List<SpotifyTracksPackageToLikeRealm>()
    let notFoundTracks = List<SharedTrackRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifyLikeTracksSuboperationRealm {
    var spotifyLikeTracksSuboperation: SpotifyLikeTracksSuboperation {
        SpotifyLikeTracksSuboperation(
            id: id,
            started: started as Date?,
            completed: completed as Date?,
            trackPackagesToLike: trackPackagesToLike.map { $0.tracksPackage },
            notFoundTracks: notFoundTracks.map { $0.sharedTrack }
        )
    }
    
    convenience init(_ spotifyLikeTracksSuboperation: SpotifyLikeTracksSuboperation) {
        self.init()
        
        id = spotifyLikeTracksSuboperation.id
        
        started = spotifyLikeTracksSuboperation.started as NSDate?
        completed = spotifyLikeTracksSuboperation.completed as NSDate?
        
        trackPackagesToLike.append(objectsIn: spotifyLikeTracksSuboperation.trackPackagesToLike.map { SpotifyTracksPackageToLikeRealm($0) })
        notFoundTracks.append(objectsIn: spotifyLikeTracksSuboperation.notFoundTracks.map { SharedTrackRealm($0) })
    }
}
