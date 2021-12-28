//
//  LastFmTrackSearchResult.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 28.12.2021.
//

import Foundation

struct LastFmTrackSearchResult: Codable {
    
    let results: Results
}

extension LastFmTrackSearchResult {
    
    struct Results: Codable {
        let opensearchQuery: OpensearchQuery
        let opensearchTotalResults, opensearchStartIndex, opensearchItemsPerPage: String
        let trackmatches: Trackmatches
        let attr: Attr

        enum CodingKeys: String, CodingKey {
            case opensearchQuery = "opensearch:Query"
            case opensearchTotalResults = "opensearch:totalResults"
            case opensearchStartIndex = "opensearch:startIndex"
            case opensearchItemsPerPage = "opensearch:itemsPerPage"
            case trackmatches
            case attr = "@attr"
        }
    }

    struct Attr: Codable {
    }

    struct OpensearchQuery: Codable {
        let text, role, startPage: String

        enum CodingKeys: String, CodingKey {
            case text = "#text"
            case role, startPage
        }
    }
    
    struct Trackmatches: Codable {
        let track: [Track]
    }

    struct Track: Codable {
        let name, artist: String
        let url: String
        let streamable: Streamable?
        let listeners: String?
        let image: [Image]?
        let mbid: String
    }

    struct Image: Codable {
        let text: String
        let size: Size

        enum CodingKeys: String, CodingKey {
            case text = "#text"
            case size
        }
    }

    enum Size: String, Codable {
        case extralarge = "extralarge"
        case large = "large"
        case medium = "medium"
        case small = "small"
    }

    enum Streamable: String, Codable {
        case fixme = "FIXME"
    }
}
