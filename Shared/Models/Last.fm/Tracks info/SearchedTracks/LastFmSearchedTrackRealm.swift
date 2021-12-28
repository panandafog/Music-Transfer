//
//  LastFmSearchedTrackRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

// swiftlint:disable force_unwrapping

import Foundation
import RealmSwift

class LastFmSearchedTrackRealm: Object {
    @objc dynamic var id = ""
    
    @objc dynamic var trackToSearch: SharedTrackRealm?
    @objc dynamic var triedToSearchTracks = false
    
    let foundTracks = List<LastFmTrackRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension LastFmSearchedTrackRealm {
    var searchedTrack: LastFmSearchedTrack {
        LastFmSearchedTrack(
            trackToSearch: trackToSearch!.sharedTrack,
            foundTracks: foundTracks.map { $0.lastFmTrack }
        )
    }
    
    convenience init(_ searchedTrack: LastFmSearchedTrack) {
        self.init()
        
        id = searchedTrack.id
        trackToSearch = SharedTrackRealm(searchedTrack.trackToSearch)
        foundTracks.append(objectsIn: searchedTrack.foundTracks?.map { LastFmTrackRealm($0) } ?? [])
        triedToSearchTracks = searchedTrack.foundTracks != nil
    }
}
