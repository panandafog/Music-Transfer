//
//  VKArtistRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import Foundation
import RealmSwift

class VKArtistRealm: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var domain = ""
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension VKArtistRealm {
    
    var vkSavedArtist: VKSavedTracks.Artist {
        VKSavedTracks.Artist(name: name, domain: domain, id: id)
    }
    
    convenience init(_ vkSavedArtist: VKSavedTracks.Artist) {
        self.init()
        
        id = vkSavedArtist.id
        name = vkSavedArtist.name
        domain = vkSavedArtist.domain
    }
}
