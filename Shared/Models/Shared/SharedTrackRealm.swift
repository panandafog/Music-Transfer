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
    let serverID = RealmProperty<Int?>()
    
    @objc dynamic var title = ""
    
    @objc dynamic var spotifyID: String?
    
    @objc dynamic var lastFmID: String?
    
    @objc dynamic var vkID: String?
    @objc dynamic var vkOwnerID: String?
    
    let artists = List<String>()
    let duration = RealmProperty<Int?>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SharedTrackRealm {
    
    var sharedTrack: SharedTrack {
        SharedTrack(
            id: id,
            serverID: serverID.value,
            artists: Array(artists),
            title: title,
            duration: duration.value,
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
        serverID.value = sharedTrack.serverID
        title = sharedTrack.title
        duration.value = sharedTrack.duration
        artists.append(objectsIn: sharedTrack.artists)
        
        sharedTrack.servicesData.forEach { serviceData in
            switch serviceData {
            case .lastFM(let id):
                lastFmID = id
            case .spotify(let id):
                spotifyID = id
            case .vk(let vkTrackData):
                vkID = vkTrackData.id
                vkOwnerID = vkTrackData.ownerID
            }
        }
    }
}
