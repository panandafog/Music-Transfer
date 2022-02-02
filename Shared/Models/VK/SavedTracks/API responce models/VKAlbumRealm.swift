//
//  VKAlbumRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import Foundation
import RealmSwift

class VKAlbumRealm: Object {
    
    @objc dynamic var id = 0
    @objc dynamic var title = ""
    @objc dynamic var ownerID = 0
    @objc dynamic var accessKey = ""
    
    let artists = List<SpotifyArtistRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension VKAlbumRealm {
    
    var vkSavedAlbum: VKSavedTracks.Album {
        VKSavedTracks.Album(
            id: id,
            title: title,
            ownerID: ownerID,
            accessKey: accessKey,
            thumb: nil
        )
    }
    
    convenience init(_ vkSavedAlbum: VKSavedTracks.Album) {
        self.init()
        
        id = vkSavedAlbum.id
        title = vkSavedAlbum.title
        ownerID = vkSavedAlbum.ownerID
        accessKey = vkSavedAlbum.accessKey
    }
}
