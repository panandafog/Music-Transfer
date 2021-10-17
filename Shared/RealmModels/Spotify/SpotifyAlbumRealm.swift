//
//  SpotifyAlbumRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

class SpotifyAlbumRealm: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    
    let artists = List<SpotifyArtistRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifyAlbumRealm {
    
    var spotifySearchedAlbum: SpotifySearchTracks.Album {
        SpotifySearchTracks.Album(
            id: id,
            name: name,
            artists: Array(artists)
        )
    }
    
    var spotifySavedAlbum: SpotifySavedTracks.Album {
        SpotifySavedTracks.Album(
            id: id,
            name: name,
            artists: Array(artists),
            href: nil,
            images: nil,
            release_date: nil,
            total_tracks: nil,
            type: nil,
            uri: nil
        )
    }
    
    convenience init(_ spotifySearchedAlbum: SpotifySearchTracks.Album) {
        self.init()
        
        id = spotifySearchedAlbum.id
        name = spotifySearchedAlbum.name
        artists.append(objectsIn: spotifySearchedAlbum.artists.map({ SpotifyArtistRealm($0) }))
    }
    
    convenience init(_ spotifySavedAlbum: SpotifySavedTracks.Album) {
        self.init()
        
        id = spotifySavedAlbum.id
        name = spotifySavedAlbum.name
        artists.append(objectsIn: spotifySavedAlbum.artists.map({ SpotifyArtistRealm($0) }))
    }
}
