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
    @objc dynamic var duration = 0
    
    @objc dynamic var spotifyID: String?
    
    @objc dynamic var lastFmID: String?
    
    @objc dynamic var vkID: String?
    @objc dynamic var vkOwnerID: String?
    
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
            duration: duration,
            servicesData: servicesData
        )
    }
    
    var servicesData: [SharedServicesData] {
        var data: [SharedServicesData] = []
        
        if let spotifyID = spotifyID {
            data.append(.spotify(spotifyID))
        }
        
        if let lastFmID = lastFmID {
            data.append(.lastFM(lastFmID))
        }
        
        if let vkID = vkID, let vkOwnerID = vkOwnerID {
            data.append(.vk(.init(id: vkID, ownerID: vkOwnerID)))
        }
        
        return data
    }
    
    convenience init(_ sharedTrack: SharedTrack) {
        self.init()
        
        id = sharedTrack.id
        title = sharedTrack.title
        duration = sharedTrack.duration
        artists.append(objectsIn: sharedTrack.artists)
    }
}
