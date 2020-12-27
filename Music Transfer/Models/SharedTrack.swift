//
//  SharedTrack.swift
//  Music Transfer
//
//  Created by panandafog on 20.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation

struct SharedTrack: Identifiable {
    var id: String
    let artists: [String]
    let title: String
    let durationS: Int
    
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
                let regEx = try NSRegularExpression (pattern: pattern, options: [])
                let nsString = artistsStr as NSString
                let range = NSMakeRange(0, nsString.length)
                artistsStr = regEx.stringByReplacingMatches(in: artistsStr,
                                                            options: .withTransparentBounds,
                                                            range: range,
                                                            withTemplate: ", ")
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
        self.durationS = track.duration_ms / 1000
    }
    
    init(from item: SpotifySavedTracks.Item) {
        let track = item.track
        self.init(from: track)
    }
    
    func strArtists() -> String {
        var res = ""
        if artists.count > 1 {
            for index in 0...artists.count - 2 {
                res.append(artists[index] + ", ")
            }
        }
        if !artists.isEmpty {
            res.append(artists.last!)
        }
        return res
    }
    
    static func makeArray(from list: SpotifySavedTracks.TracksList) -> [SharedTrack] {
        var res = [SharedTrack]()
        
        list.items.forEach({
            res.append(SharedTrack(from: $0))
        })
        
        return res
    }
    
    static func makeArray(from list: VKSavedTracks.TracksList) -> [SharedTrack] {
        var res = [SharedTrack]()
        
        list.response.items.forEach({
            res.append(SharedTrack(from: $0))
        })
        
        return res
    }
}

extension SharedTrack: Equatable {
    static func == (lhs: SharedTrack, rhs: SharedTrack) -> Bool {
        
        guard !lhs.artists.isEmpty && !rhs.artists.isEmpty else {
            return false
        }
        
        var lhsArtists = [String]()
        lhs.artists.forEach({
            lhsArtists.append($0.lowercased())
        })
        
        var rhsArtists = [String]()
        rhs.artists.forEach({
            rhsArtists.append($0.lowercased())
        })
        
        var equalArtistsL = true
        for artistL in lhsArtists {
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
                break
            }
        }
        
        var equalArtists_r = true
        for artistR in lhsArtists {
            var contains = false
            if rhsArtists.contains(artistR) {
                contains = true
            } else {
                for artistL in rhsArtists {
                    if artistL.contains(artistR) {
                        contains = true
                    }
                }
            }
            if !contains {
                equalArtists_r = false
                break
            }
        }
        
        let equalArtists = equalArtistsL || equalArtists_r
        
        return equalArtists && titlesAreEqual(lhs: lhs.title, rhs: rhs.title)
    }
    
    static func ~= (lhs: SharedTrack, rhs: SharedTrack) -> Bool {
        
        guard !lhs.artists.isEmpty && !rhs.artists.isEmpty else {
            return false
        }
        
        var lhsArtists = [String]()
        lhs.artists.forEach({
            lhsArtists.append($0.lowercased())
        })
        
        var rhsArtists = [String]()
        rhs.artists.forEach({
            rhsArtists.append($0.lowercased())
        })
        
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
        
        let equalArtists = equalArtistsL || equalArtistsR
        
        return equalArtists && titlesAreEqual(lhs: lhs.title, rhs: rhs.title)
    }
    
    static func titlesAreEqual(lhs: String, rhs: String) -> Bool {
        let clearLhs = clearTitle(lhs)
        let clearRhs = clearTitle(rhs)
        
        return rhs.contains(clearLhs) || lhs.contains(clearRhs) || lhs == rhs
    }
    
    static func clearTitle(_ title: String) -> String {
        var title = title
        let patterns = ["\\ *\\(.*\\)", "\\ *\\[.*\\]"]
        do {
            for pattern in patterns {
                let regEx = try NSRegularExpression (pattern: pattern, options: [])
                let nsString = title as NSString
                let range = NSMakeRange(0, nsString.length)
                title = regEx.stringByReplacingMatches(in: title,
                                                       options: .withTransparentBounds,
                                                       range: range,
                                                       withTemplate: "")
            }
        } catch _ as NSError {
        }
        
        return title
    }
}
