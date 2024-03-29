//
//  LastFmTrackRealm.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import Foundation
import RealmSwift

class LastFmTrackRealm: Object {
    @objc dynamic var id = ""
    @objc dynamic var mbid = ""
    @objc dynamic var name = ""
    @objc dynamic var artist = ""
    @objc dynamic var url = ""
    
    override class func primaryKey() -> String? {
        "id"
    }
}

extension LastFmTrackRealm {
    
    var lastFmTrack: LastFmTrackSearchResult.Track {
        LastFmTrackSearchResult.Track(
            id: id,
            name: name,
            artist: artist,
            url: url,
            streamable: nil,
            listeners: nil,
            image: nil,
            mbid: mbid
        )
    }
    
    convenience init(_ lastFmTrack: LastFmTrackSearchResult.Track) {
        self.init()
        
        id = lastFmTrack.id
        name = lastFmTrack.name
        artist = lastFmTrack.artist
        url = lastFmTrack.url
        mbid = lastFmTrack.mbid
    }
}
