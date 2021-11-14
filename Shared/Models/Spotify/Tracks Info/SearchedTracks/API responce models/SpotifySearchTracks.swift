//
//  SpotifySearchTracks.swift
//  Music Transfer
//
//  Created by panandafog on 20.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation

enum SpotifySearchTracks {
    
    // MARK: - TracksList
    struct TracksList: Codable {
        let tracks: Tracks
    }
    
    // MARK: - Tracks
    struct Tracks: Codable {
        let items: [Item]
        let next: String?
        let offset: Int
        let previous: String?
        let total: Int
    }
    
    // MARK: - Item
    struct Item: Codable {
        let id: String
        let name: String
        let disc_number, duration_ms: Int
        let album: Album?
        let artists: [Artist]
    }
    
    // MARK: - Album
    struct Album: Codable {
        let id: String
        let name: String
        let artists: [Artist]
    }
    
    // MARK: - Artist
    struct Artist: Codable {
        let id, name, uri: String
        let type: ArtistType?
    }
    
    enum ArtistType: String, Codable {
        case artist
    }
}
