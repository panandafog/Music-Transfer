//
//  SharedTrack.swift
//  Music Transfer
//
//  Created by panandafog on 20.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation

struct SharedTrack: Identifiable {
    
    // MARK: - Constants
    
    /// percents
    static let durationComparisonInaccuracy = 10
    
    // MARK: - Instance properties
    
    var id = NSUUID().uuidString
    var serverID: Int?
    
    let artists: [String]
    let title: String
    
    /// seconds
    let duration: Int?
    
    let servicesData: [SharedServicesData]
    
    var descriptionString: String {
        let durationString: String
        if let duration = duration {
            durationString = [
                ", duration:",
                String(duration)
            ].joined()
        } else {
            durationString = ""
        }
        return [
            artists.joined(separator: ", "),
            " – ",
            title,
            durationString
        ].joined()
    }
    
    // MARK: - Initializers
    
    init(id: String = NSUUID().uuidString, serverID: Int?, artists: [String], title: String, duration: Int?, servicesData: [SharedServicesData]) {
        self.id = id
        self.serverID = serverID
        self.artists = artists
        self.title = title
        self.duration = duration
        self.servicesData = servicesData
    }
    
    init(from track: VKSavedTracks.Item) {
        var artistsStr = track.artist
        
        let patterns = [" feat. ", " ft. "]
        do {
            for pattern in patterns {
                let regEx = try NSRegularExpression(pattern: pattern, options: [])
                let nsString = artistsStr as NSString
                let range = NSRange(location: 0, length: nsString.length)
                artistsStr = regEx.stringByReplacingMatches(
                    in: artistsStr,
                    options: .withTransparentBounds,
                    range: range,
                    withTemplate: ", "
                )
            }
        } catch _ as NSError {
            print("Matching failed")
        }
        
        let artistsArray = artistsStr.components(separatedBy: ", ")
        
        self.artists = artistsArray
        self.title = track.title
        self.duration = track.duration
        
        if let serverID = track.serverID {
            self.servicesData = [
                .vk(
                    SharedServicesData.VKTrackData(
                        id: String(serverID),
                        ownerID: String(track.owner_id)
                    )
                )
            ]
        } else {
            self.servicesData = [ ]
        }
    }
    
    init(from track: SpotifySavedTracks.Track) {
        var artists = [String]()
        for artist in track.artists {
            artists.append(artist.name)
        }
        
        self.artists = artists
        self.title = track.name
        self.duration = track.duration_ms / 1_000
        
        self.servicesData = [
            .spotify(track.id)
        ]
    }
    
    init(from item: SpotifySavedTracks.Item) {
        let track = item.track
        self.init(from: track)
    }
    
    init(from item: SpotifySearchTracks.Item) {
        var artists = [String]()
        for artist in item.artists {
            artists.append(artist.name)
        }
        
        self.artists = artists
        self.title = item.name
        self.duration = item.duration_ms / 1_000
        
        self.servicesData = [
            .spotify(item.id)
        ]
    }
    
    init(from track: LastFmLovedTracks.Track) {
        self.artists = [track.artist.name]
        self.title = track.name
        self.duration = nil
        
        self.servicesData = [
            .lastFM(track.id)
        ]
    }
    
    init(from track: LastFmTrackSearchResult.Track) {
        self.artists = [track.artist]
        self.title = track.name
        self.duration = nil
        
        self.servicesData = [
            .lastFM(track.id)
        ]
    }
    
    // MARK: - Making array methods
    
    static func makeArray(from list: SpotifySavedTracks.TracksList) -> [SharedTrack] {
        var res = [SharedTrack]()
        
        list.items.forEach {
            res.append(SharedTrack(from: $0))
        }
        
        return res
    }
    
    static func makeArray(from list: VKSavedTracks.TracksList) -> [SharedTrack] {
        var res = [SharedTrack]()
        
        list.response.items.forEach {
            res.append(SharedTrack(from: $0))
        }
        
        return res
    }
    
    static func makeArray(from lovedTracks: LastFmLovedTracks) -> [SharedTrack] {
        makeArray(from: lovedTracks.lovedtracks)
    }
    
    static func makeArray(from lovedTracks: LastFmLovedTracks.LovedTracks) -> [SharedTrack] {
        var res = [SharedTrack]()
        
        lovedTracks.track.forEach {
            res.append(SharedTrack(from: $0))
        }
        
        return res
    }
    
    // MARK: - Making string methods
    
    func strArtists() -> String {
        artists.joined(separator: ", ")
    }
}
