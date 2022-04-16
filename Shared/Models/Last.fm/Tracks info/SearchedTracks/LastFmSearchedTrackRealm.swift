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
    let serverID = RealmProperty<Int?>()
    
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
            id: id,
            serverID: serverID.value,
            trackToSearch: trackToSearch!.sharedTrack,
            foundTracks: triedToSearchTracks ? foundTracks.map { $0.lastFmTrack } : nil
        )
    }
    
    convenience init(_ searchedTrack: LastFmSearchedTrack) {
        self.init()
        
        id = searchedTrack.id
        serverID.value = searchedTrack.serverID
        trackToSearch = SharedTrackRealm(searchedTrack.trackToSearch)
        foundTracks.append(objectsIn: searchedTrack.foundTracks?.map { LastFmTrackRealm($0) } ?? [])
        triedToSearchTracks = searchedTrack.foundTracks != nil
    }
}
