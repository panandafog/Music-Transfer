//
//  VKSearchedItemRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import Foundation
import RealmSwift

class VKSavedItemRealm: Object {
    
    @objc dynamic var id = 0
    @objc dynamic var title = ""
    @objc dynamic var artist = ""
    @objc dynamic var ownerID = 0
    @objc dynamic var duration = 0
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension VKSavedItemRealm {
    
    var vkSavedItem: VKSavedTracks.Item {
        VKSavedTracks.Item(
            artist: artist,
            id: id,
            owner_id: ownerID,
            title: title,
            duration: duration
        )
    }
    
    convenience init(_ vkSavedItem: VKSavedTracks.Item) {
        self.init()
        
        id = vkSavedItem.id
        title = vkSavedItem.title
        artist = vkSavedItem.artist
        ownerID = vkSavedItem.owner_id
        duration = vkSavedItem.duration
    }
}
