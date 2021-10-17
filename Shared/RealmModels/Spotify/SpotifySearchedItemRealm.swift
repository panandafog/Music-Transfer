//
//  SpotifySearchedItemRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

class SpotifySearchedItemRealm: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var discNumber = 0
    @objc dynamic var durationMs = 0
    
    @objc dynamic var album: SpotifyAlbumRealm?
    let artists = List<SpotifyArtistRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifySearchedItemRealm {
    
    var spotifySearchedItem: SpotifySearchTracks.Item {
        SpotifySearchTracks.Item(
            id: id,
            name: name,
            disc_number: discNumber,
            duration_ms: durationMs,
            album: album?.spotifySearchedAlbum,
            artists: Array(artists)
        )
    }
    
    convenience init(_ spotifySearchedItem: SpotifySearchTracks.Item) {
        self.init()
        
        id = spotifySearchedItem.id
        name = spotifySearchedItem.name
        discNumber = spotifySearchedItem.disc_number
        durationMs = spotifySearchedItem.duration_ms
        if let album = spotifySearchedItem.album {
            self.album = SpotifyAlbumRealm(album)
        }
        artists.append(objectsIn: spotifySearchedItem.artists.map({ SpotifyArtistRealm($0) }))
    }
}
