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
            let track = $0.track
            var artists = [String]()
            for artist in $0.track.artists {
                artists.append(artist.name)
            }
            
            res.append(SharedTrack(id: track.id,
                                   artists: artists,
                                   title: track.name,
                                   durationS: track.duration_ms / 1000))
        })
        
        return res
    }
    
    static func makeArray(from list: VKSavedTracks.TracksList) -> [SharedTrack] {
        var res = [SharedTrack]()
        
        for track in list.response.items {
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
            
            res.append(SharedTrack(id: String(track.id),
                                   artists: artistsArray,
                                   title: track.title,
                                   durationS: track.duration))
        }
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
        
        var clearTitle = lhs.title
        
        let patterns = ["\\ *\\(.*\\)\\ *"]
        do {
            for pattern in patterns {
                let regEx = try NSRegularExpression (pattern: pattern, options: [])
                let nsString = clearTitle as NSString
                let range = NSMakeRange(0, nsString.length)
                clearTitle = regEx.stringByReplacingMatches(in: clearTitle,
                                                            options: .withTransparentBounds,
                                                            range: range,
                                                            withTemplate: "")
            }
        } catch _ as NSError {
            print("Matching failed")
        }
        
        return equalArtists && rhs.title.contains(clearTitle)
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
        
        var clearTitle = lhs.title
        
        let patterns = ["\\ *\\(.*\\)\\ *"]
        do {
            for pattern in patterns {
                let regEx = try NSRegularExpression (pattern: pattern, options: [])
                let nsString = clearTitle as NSString
                let range = NSMakeRange(0, nsString.length)
                clearTitle = regEx.stringByReplacingMatches(in: clearTitle,
                                                            options: .withTransparentBounds,
                                                            range: range,
                                                            withTemplate: "")
            }
        } catch _ as NSError {
            print("Matching failed")
        }
        
        return equalArtists && rhs.title.contains(clearTitle)
    }
}
