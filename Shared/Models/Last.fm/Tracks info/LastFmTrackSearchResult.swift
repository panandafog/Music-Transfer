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

    class Track: Codable {
        let id: String
        var serverID: Int?
        
        let name, artist: String
        let url: String
        let streamable: Streamable?
        let listeners: String?
        let image: [Image]?
        let mbid: String
        
        init(
            id: String? = nil,
            serverID: Int?,
            name: String,
            artist: String,
            url: String,
            streamable: Streamable?,
            listeners: String?,
            image: [Image]?,
            mbid: String
        ) {
            self.id = id ?? NSUUID().uuidString
            self.serverID = serverID
            
            self.name = name
            self.artist = artist
            self.url = url
            self.streamable = streamable
            self.listeners = listeners
            self.image = image
            self.mbid = mbid
        }
        
        required init(from decoder: Decoder) throws {
            id = NSUUID().uuidString
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            name = try container.decode(String.self, forKey: .name)
            artist = try container.decode(String.self, forKey: .artist)
            url = try container.decode(String.self, forKey: .url)
            streamable = try container.decodeIfPresent(Streamable.self, forKey: .streamable)
            listeners = try container.decodeIfPresent(String.self, forKey: .listeners)
            image = try container.decodeIfPresent([Image].self, forKey: .image)
            mbid = try container.decode(String.self, forKey: .mbid)
        }
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
        case extralarge
        case large
        case medium
        case small
    }

    enum Streamable: String, Codable {
        case fixme = "FIXME"
    }
}
