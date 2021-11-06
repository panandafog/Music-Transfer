//
//  SpotifyTrackToLikeRealm.swift
//  Music Transfer
//
//  Created by panandafog on 24.10.2021.
//

import RealmSwift

class SpotifyTracksPackageToLikeRealm: Object {
    @objc dynamic var id = ""
    @objc dynamic var liked = false
    
    let tracks = List<SpotifySearchedItemRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifyTracksPackageToLikeRealm {
    var tracksPackage: SpotifyTracksPackageToLike {
        SpotifyTracksPackageToLike(
            id: id,
            tracks: tracks.map { $0.spotifySearchedItem },
            liked: liked
        )
    }
    
    convenience init(_ package: SpotifyTracksPackageToLike) {
        self.init()
        
        id = package.id
        tracks.append(objectsIn: package.tracks.map { SpotifySearchedItemRealm($0) })
        liked = package.liked
    }
}
