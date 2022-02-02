//
//  SpotifySavedTracks.swift
//  Music Transfer
//
//  Created by panandafog on 12.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

// swiftlint:disable discouraged_optional_boolean

import Foundation

enum SpotifySavedTracks {
    
    // MARK: - TracksList
    struct TracksList: Codable {
        let href: String
        let items: [Item]
        let limit: Int
        let next: String?
        let offset: Int
        let total: Int
    }
    
    // MARK: - Item
    struct Item: Codable {
        let added_at: String
        let track: Track
    }
    
    // MARK: - Track
    struct Track: Codable {
        let id: String
        let name: String
        let disc_number: Int
        let duration_ms: Int
        let album: Album?
        let artists: [Artist]
        
        let explicit: Bool?
        let href: String?
        let is_local: Bool?
        let popularity: Int?
        let preview_url: String?
        let track_number: Int?
        let uri: String?
    }
    
    // MARK: - Album
    struct Album: Codable {
        let id: String
        let name: String
        let artists: [Artist]
        
        let href: String?
        let images: [Image]?
        let release_date: String?
        let total_tracks: Int?
        let type: AlbumTypeEnum?
        let uri: String?
    }
    
    enum AlbumTypeEnum: String, Codable {
        case album
        case single
    }
    
    // MARK: - Artist
    struct Artist: Codable {
        let id, name: String
        let type: ArtistType?
        let uri: String
        let href: String?
    }
    
    // MARK: - ExternalUrls
    struct ExternalUrls: Codable {
        let spotify: String
    }
    
    enum ArtistType: String, Codable {
        case artist
    }
    
    // MARK: - Image
    struct Image: Codable {
        let height: Int
        let url: String
        let width: Int
    }
    
    // MARK: - ExternalIDS
    struct ExternalIDS: Codable {
        let isrc: String
    }
    
    enum TrackType: String, Codable {
        case track
    }
}
