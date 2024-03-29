//
//  VKSearchTracksSuboperationRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import Foundation
import RealmSwift

class VKSearchTracksSuboperationRealm: Object {
    
    @objc dynamic var id = ""
    
    @objc dynamic var started: NSDate?
    @objc dynamic var completed: NSDate?
    
    let tracks = List<VKSearchedTrackRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension VKSearchTracksSuboperationRealm {
    var vkSearchTracksSuboperation: VKSearchTracksSuboperation {
        VKSearchTracksSuboperation(
            id: id,
            started: started as Date?,
            completed: completed as Date?,
            tracks: tracks.map { $0.searchedTrack }
        )
    }
    
    convenience init(_ vkSearchTracksSuboperation: VKSearchTracksSuboperation) {
        self.init()
        
        id = vkSearchTracksSuboperation.id
        
        started = vkSearchTracksSuboperation.started as NSDate?
        completed = vkSearchTracksSuboperation.completed as NSDate?
        tracks.append(objectsIn: vkSearchTracksSuboperation.tracks.map { VKSearchedTrackRealm($0) })
    }
}
