//
//  SpotifySavedItemRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

class SpotifySavedItemRealm: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var discNumber = 0
    @objc dynamic var durationMs = 0
    @objc dynamic var addedAt = ""
    
    @objc dynamic var album: SpotifyAlbumRealm?
    let artists = List<SpotifyArtistRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifySavedItemRealm {
    
    var spotifySavedItem: SpotifySavedTracks.Item {
        let track = SpotifySavedTracks.Track(
            id: id,
            name: name,
            disc_number: discNumber,
            duration_ms: durationMs,
            album: album?.spotifySavedAlbum,
            artists: Array(artists),
            explicit: nil,
            href: nil,
            is_local: nil,
            popularity: nil,
            preview_url: nil,
            track_number: nil,
            uri: nil
        )
        return SpotifySavedTracks.Item(
            added_at: addedAt,
            track: track
        )
    }
    
    convenience init(_ spotifySavedItem: SpotifySavedTracks.Item) {
        self.init()
        
        id = spotifySavedItem.track.id
        name = spotifySavedItem.track.name
        discNumber = spotifySavedItem.track.disc_number
        durationMs = spotifySavedItem.track.duration_ms
        if let album = spotifySavedItem.track.album {
            self.album = SpotifyAlbumRealm(album)
        }
        artists.append(objectsIn: spotifySavedItem.track.artists.map({ SpotifyArtistRealm($0) }))
        addedAt = spotifySavedItem.added_at
    }
}
