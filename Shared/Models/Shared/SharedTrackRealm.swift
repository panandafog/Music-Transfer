//
//  SharedTrackRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

class SharedTrackRealm: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var title = ""
    @objc dynamic var durationS = 0
    
    let artists = List<String>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SharedTrackRealm {
    
    var sharedTrack: SharedTrack {
        SharedTrack(
            id: id,
            artists: Array(artists),
            title: title,
            durationS: durationS
        )
    }
    
    convenience init(_ sharedTrack: SharedTrack) {
        self.init()
        
        id = sharedTrack.id
        title = sharedTrack.title
        durationS = sharedTrack.durationS
        artists.append(objectsIn: sharedTrack.artists)
    }
}
