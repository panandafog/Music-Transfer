//
//  SharedTrack.swift
//  Music Transfer
//
//  Created by panandafog on 20.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation

struct SharedTrack {
    
    let artists: [String]
    let title: String
    let durationS: Int
    
    func strArtists() -> String {
        var res = ""
        if artists.count > 1 {
            artists.forEach({
                res.append($0 + ", ")
            })
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
                artists.append(artist.name.lowercased())
            }
            
            res.append(SharedTrack(artists: artists,
                                   title: track.name.lowercased(),
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
            
            let artistsArray = artistsStr.lowercased().components(separatedBy: ", ")
            
            res.append(SharedTrack(artists: artistsArray,
                                   title: track.title.lowercased(),
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
        
        var equalArtists_l = true
        for artist_l in lhs.artists {
            var contains = false
            if rhs.artists.contains(artist_l) {
                contains = true
            } else {
                for artist_r in rhs.artists {
                    if artist_r.contains(artist_l) {
                        contains = true
                    }
                }
            }
            if !contains {
                equalArtists_l = false
                break
            }
        }
        
        var equalArtists_r = true
        for artist_r in lhs.artists {
            var contains = false
            if rhs.artists.contains(artist_r) {
                contains = true
            } else {
                for artist_l in rhs.artists {
                    if artist_l.contains(artist_r) {
                        contains = true
                    }
                }
            }
            if !contains {
                equalArtists_r = false
                break
            }
        }
        
        let equalArtists = equalArtists_l || equalArtists_r
        
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
        
        var equalArtists_l = true
        let artist_l = lhs.artists[0]
        var contains = false
        if rhs.artists.contains(artist_l) {
            contains = true
        } else {
            for artist_r in rhs.artists {
                if artist_r.contains(artist_l) {
                    contains = true
                }
            }
        }
        if !contains {
            equalArtists_l = false
        }
        
        
        var equalArtists_r = true
        let artist_r = rhs.artists[0]
        contains = false
        if lhs.artists.contains(artist_r) {
            contains = true
        } else {
            for artist_l in lhs.artists {
                if artist_l.contains(artist_r) {
                    contains = true
                }
            }
        }
        if !contains {
            equalArtists_r = false
        }
        
        
        let equalArtists = equalArtists_l || equalArtists_r
        
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
