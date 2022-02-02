//
//  SpotifySearchedTrackRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

// swiftlint:disable force_unwrapping

import Foundation
import RealmSwift

class SpotifySearchedTrackRealm: Object {
    @objc dynamic var id = ""
    
    @objc dynamic var trackToSearch: SharedTrackRealm?
    @objc dynamic var triedToSearchTracks = false
    
    let foundTracks = List<SpotifySearchedItemRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension SpotifySearchedTrackRealm {
    var searchedTrack: SpotifySearchedTrack {
        SpotifySearchedTrack(
            trackToSearch: trackToSearch!.sharedTrack,
            foundTracks: foundTracks.map { $0.spotifySearchedItem }
        )
    }
    
    convenience init(_ searchedTrack: SpotifySearchedTrack) {
        self.init()
        
        id = searchedTrack.id
        trackToSearch = SharedTrackRealm(searchedTrack.trackToSearch)
        foundTracks.append(objectsIn: searchedTrack.foundTracks?.map { SpotifySearchedItemRealm($0) } ?? [])
        triedToSearchTracks = searchedTrack.foundTracks != nil
    }
}
