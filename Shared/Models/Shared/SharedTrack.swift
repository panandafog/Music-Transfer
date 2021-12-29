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
    
    /// in percents
    static let durationComparisonInaccuracy = 10
    
    // MARK: - Instance properties
    
    var id = NSUUID().uuidString
    let artists: [String]
    let title: String
    let durationS: Int
    
    // MARK: - Initializers

    init(id: String, artists: [String], title: String, durationS: Int) {
        self.id = id
        self.artists = artists
        self.title = title
        self.durationS = durationS
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
        
        self.id = String(track.id)
        self.artists = artistsArray
        self.title = track.title
        self.durationS = track.duration
    }
    
    init(from track: SpotifySavedTracks.Track) {
        var artists = [String]()
        for artist in track.artists {
            artists.append(artist.name)
        }
        
        self.id = track.id
        self.artists = artists
        self.title = track.name
        self.durationS = track.duration_ms / 1_000
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
        
        self.id = item.id
        self.artists = artists
        self.title = item.name
        self.durationS = item.duration_ms / 1_000
    }
    
    init(from track: LastFmLovedTracks.Track) {
        self.id = track.mbid
        self.artists = [track.artist.name]
        self.title = track.name
        self.durationS = 0
    }
    
    init(from track: LastFmTrackSearchResult.Track) {
        self.id = track.mbid
        self.artists = [track.artist]
        self.title = track.name
        self.durationS = 0
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
        var res = ""
        if artists.count > 1 {
            for index in 0...artists.count - 2 {
                res.append(artists[index] + ", ")
            }
        }
        if !artists.isEmpty, let last = artists.last {
            res.append(last)
        }
        return res
    }
}

// MARK: - Extensions

extension SharedTrack: Equatable {
    
    static func == (lhs: SharedTrack, rhs: SharedTrack) -> Bool {
        
        guard lhs ~= rhs else {
            return false
        }
        
        var lhsArtists = [String]()
        lhs.artists.forEach {
            lhsArtists.append($0.lowercased())
        }
        
        var rhsArtists = [String]()
        rhs.artists.forEach {
            rhsArtists.append($0.lowercased())
        }
        
        var equalArtistsL = true
        let artistL = lhsArtists[0]
        var contains = false
        if rhsArtists.contains(artistL) {
            contains = true
        } else {
            for artistR in rhsArtists {
                if artistR.contains(artistL) {
                    contains = true
                }
            }
        }
        if !contains {
            equalArtistsL = false
        }
        
        var equalArtistsR = true
        let artistR = rhsArtists[0]
        contains = false
        if lhsArtists.contains(artistR) {
            contains = true
        } else {
            for artistL in lhsArtists {
                if artistL.contains(artistR) {
                    contains = true
                }
            }
        }
        if !contains {
            equalArtistsR = false
        }
        
        return equalArtistsL || equalArtistsR
    }
    
    static func ~= (lhs: SharedTrack, rhs: SharedTrack) -> Bool {
        
        guard !lhs.artists.isEmpty && !rhs.artists.isEmpty else {
            return false
        }
        
        var lhsArtists = [String]()
        lhs.artists.forEach {
            lhsArtists.append($0.lowercased())
        }
        
        var rhsArtists = [String]()
        rhs.artists.forEach {
            rhsArtists.append($0.lowercased())
        }
        
        var equalArtistsL = true
        let artistL = lhsArtists[0]
        var contains = false
        if rhsArtists.contains(artistL) {
            contains = true
        } else {
            if rhs.title.lowercased().contains(artistL) {
                contains = true
            } else {
                for artistR in rhsArtists {
                    if artistR.contains(artistL) {
                        contains = true
                    }
                }
            }
        }
        if !contains {
            equalArtistsL = false
        }
        
        var equalArtistsR = true
        let artistR = rhsArtists[0]
        contains = false
        if lhsArtists.contains(artistR) {
            contains = true
        } else {
            if lhs.title.lowercased().contains(artistR) {
                contains = true
            } else {
                for artistL in lhsArtists {
                    if artistL.contains(artistR) {
                        contains = true
                    }
                }
            }
        }
        if !contains {
            equalArtistsR = false
        }
        
        let equalArtists = equalArtistsL || equalArtistsR
        
        return equalArtists
        && titlesAreEqual(lhs: lhs.title, rhs: rhs.title)
        && durationsAreEqual(lhs: lhs.durationS, rhs: rhs.durationS)
    }
    
    static func durationsAreEqual(lhs: Int, rhs: Int) -> Bool {
        Int(Double(lhs) / Double(rhs) * 100.0) >= 100 - durationComparisonInaccuracy
        && Int(Double(lhs) / Double(rhs) * 100.0) <= 100 + durationComparisonInaccuracy
    }
    
    static func titlesAreEqual(lhs: String, rhs: String) -> Bool {
        let clearLhs = clearTitle(lhs).lowercased()
        let clearRhs = clearTitle(rhs).lowercased()
        
        return rhs.lowercased().contains(clearLhs)
        || lhs.lowercased().contains(clearRhs)
        || lhs.lowercased() == rhs.lowercased()
    }
    
    static func clearTitle(_ title: String) -> String {
        var title = title
        let patterns = ["\\ *\\(.*\\)", "\\ *\\[.*\\]"]
        do {
            for pattern in patterns {
                let regEx = try NSRegularExpression(pattern: pattern, options: [])
                let nsString = title as NSString
                let range = NSRange(location: 0, length: nsString.length)
                title = regEx.stringByReplacingMatches(
                    in: title,
                    options: .withTransparentBounds,
                    range: range,
                    withTemplate: ""
                )
            }
        } catch _ as NSError {
        }
        
        return title
    }
}
