//
//  SpotifyArtistRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

class SpotifyArtistRealm: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var type = ""
    @objc dynamic var uri = ""
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifyArtistRealm {
    
    var spotifySearchedArtist: SpotifySearchTracks.Artist {
        SpotifySearchTracks.Artist(
            id: id,
            name: name,
            uri: uri,
            type: SpotifySearchTracks.ArtistType(rawValue: type)
        )
    }
    
    var spotifySavedArtist: SpotifySavedTracks.Artist {
        SpotifySavedTracks.Artist(
            id: id,
            name: name,
            type: SpotifySavedTracks.ArtistType(rawValue: type),
            uri: uri,
            href: nil
        )
    }
    
    convenience init(_ spotifySearchedArtist: SpotifySearchTracks.Artist) {
        self.init()
        
        id = spotifySearchedArtist.id
        name = spotifySearchedArtist.name
        type = spotifySearchedArtist.type?.rawValue ?? ""
        uri = spotifySearchedArtist.uri
    }
    
    convenience init(_ spotifySavedArtist: SpotifySavedTracks.Artist) {
        self.init()
        
        id = spotifySavedArtist.id
        name = spotifySavedArtist.name
        type = spotifySavedArtist.type?.rawValue ?? ""
        uri = spotifySavedArtist.uri
    }
}
