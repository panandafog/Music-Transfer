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

    struct Track: Codable {
        let artist: Artist
        let date: DateClass
        let mbid: String
        let url: String
        let name: String
        let image: [Image]
        let streamable: Streamable
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
        case extralarge = "extralarge"
        case large = "large"
        case medium = "medium"
        case small = "small"
    }

    struct Streamable: Codable {
        let fulltrack, text: String

        enum CodingKeys: String, CodingKey {
            case fulltrack
            case text = "#text"
        }
    }
}
