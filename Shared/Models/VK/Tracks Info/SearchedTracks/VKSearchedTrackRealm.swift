//
//  VKSearchedTrackRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

// swiftlint:disable force_unwrapping

import Foundation
import RealmSwift

class VKSearchedTrackRealm: Object {
    @objc dynamic var id = ""
    
    @objc dynamic var trackToSearch: SharedTrackRealm?
    @objc dynamic var triedToSearchTracks = false
    
    let foundTracks = List<VKSavedItemRealm>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension VKSearchedTrackRealm {
    var searchedTrack: VKSearchedTrack {
        VKSearchedTrack(
            id: id,
            trackToSearch: trackToSearch!.sharedTrack,
            foundTracks: foundTracks.map { $0.vkSavedItem }
        )
    }
    
    convenience init(_ searchedTrack: VKSearchedTrack) {
        self.init()
        
        id = searchedTrack.id
        trackToSearch = SharedTrackRealm(searchedTrack.trackToSearch)
        foundTracks.append(objectsIn: searchedTrack.foundTracks?.map { VKSavedItemRealm($0) } ?? [])
        triedToSearchTracks = searchedTrack.foundTracks != nil
    }
}
