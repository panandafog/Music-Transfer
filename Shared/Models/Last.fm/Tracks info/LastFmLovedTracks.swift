//
//  LastFmLovedTracks.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 27.12.2021.
//

import Foundation

struct LastFmLovedTracks: Codable {
    let lovedtracks: LovedTracks
}

extension LastFmLovedTracks {
    
    struct LovedTracks: Codable {
        let track: [Track]
        let attr: Attr

        enum CodingKeys: String, CodingKey {
            case track
            case attr = "@attr"
        }
    }

    struct Attr: Codable {
        let user, totalPages, page, perPage: String
        let total: String
    }

    class Track: Codable {
        let id: String
        
        let artist: Artist
        let date: DateClass
        let mbid: String
        let url: String
        let name: String
        let image: [Image]?
        let streamable: Streamable?
        
        init(
            id: String? = nil,
            name: String,
            artist: Artist,
            date: DateClass,
            url: String,
            streamable: Streamable?,
            image: [Image]?,
            mbid: String
        ) {
            self.id = id ?? NSUUID().uuidString
            
            self.name = name
            self.artist = artist
            self.date = date
            self.url = url
            self.streamable = streamable
            self.image = image
            self.mbid = mbid
        }
        
        required init(from decoder: Decoder) throws {
            id = NSUUID().uuidString
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            name = try container.decode(String.self, forKey: .name)
            artist = try container.decode(Artist.self, forKey: .artist)
            date = try container.decode(DateClass.self, forKey: .date)
            url = try container.decode(String.self, forKey: .url)
            streamable = try container.decodeIfPresent(Streamable.self, forKey: .streamable)
            image = try container.decodeIfPresent([Image].self, forKey: .image)
            mbid = try container.decode(String.self, forKey: .mbid)
        }
    }

    struct Artist: Codable {
        let url: String
        let name, mbid: String
    }

    struct DateClass: Codable {
        let uts, text: String

        enum CodingKeys: String, CodingKey {
            case uts
            case text = "#text"
        }
    }

    struct Image: Codable {
        let size: Size
        let text: String

        enum CodingKeys: String, CodingKey {
            case size
            case text = "#text"
        }
    }

    enum Size: String, Codable {
        case extralarge
        case large
        case medium
        case small
    }

    struct Streamable: Codable {
        let fulltrack, text: String

        enum CodingKeys: String, CodingKey {
            case fulltrack
            case text = "#text"
        }
    }
}
