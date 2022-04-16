//
//  LastFmTrackServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct LastFmTrackServerModel: Codable {
    let id: Int?
    let mbid, name, artist, url: String
}

extension LastFmTrackServerModel {
    
    var clientModel: LastFmTrackSearchResult.Track {
        LastFmTrackSearchResult.Track(
            serverID: id,
            name: name,
            artist: artist,
            url: url,
            streamable: nil,
            listeners: nil,
            image: nil,
            mbid: mbid
        )
    }
    
    init(clientModel: LastFmTrackSearchResult.Track) {
        id = clientModel.serverID
        mbid = clientModel.mbid
        name = clientModel.name
        artist = clientModel.artist
        url = clientModel.url
    }
}
