//
//  VKLikeTracksSuboperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import Foundation
import RealmSwift

class VKLikeTracksSuboperationRealm: Object {
    
    @objc dynamic var id = ""
    
    @objc dynamic var started = false
    @objc dynamic var completed = false
    
    let tracksToLike = List<VKTrackToLikeRealm>()
    let notFoundTracks = List<SharedTrackRealm>()
    let duplicates = List<SharedTrackRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension VKLikeTracksSuboperationRealm {
    var vkLikeTracksSuboperation: VKLikeTracksSuboperation {
        VKLikeTracksSuboperation(
            id: id,
            started: started,
            completed: completed,
            tracksToLike: tracksToLike.map { $0.trackToLike },
            notFoundTracks: notFoundTracks.map { $0.sharedTrack },
            duplicates: duplicates.map { $0.sharedTrack }
        )
    }
    
    convenience init(_ vkLikeTracksSuboperation: VKLikeTracksSuboperation) {
        self.init()
        
        id = vkLikeTracksSuboperation.id
        
        started = vkLikeTracksSuboperation.started
        completed = vkLikeTracksSuboperation.completed
        
        tracksToLike.append(objectsIn: vkLikeTracksSuboperation.tracksToLike.map { VKTrackToLikeRealm($0) })
        notFoundTracks.append(objectsIn: vkLikeTracksSuboperation.notFoundTracks.map { SharedTrackRealm($0) })
        duplicates.append(objectsIn: vkLikeTracksSuboperation.duplicates.map { SharedTrackRealm($0) })
    }
}
