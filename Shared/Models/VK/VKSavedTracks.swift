//
//  VKSavedTracks.swift
//  Music Transfer
//
//  Created by panandafog on 20.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation

enum VKSavedTracks {
    
    // MARK: - TracksList
    struct TracksList: Codable {
        let response: Response
    }
    
    // MARK: - Response
    struct Response: Codable {
        let count: Int
        let items: [Item]
    }
    
    // MARK: - Item
    struct Item: Codable {
        let artist: String
        let id: Int
        let owner_id: Int
        let title: String
        let duration: Int
    }
    
    // MARK: - Ads
    struct Ads: Codable {
        let contentID, duration, accountAgeType, puid1: String
        let puid22: String
    }
    
    // MARK: - Album
    struct Album: Codable {
        let id: Int
        let title: String
        let ownerID: Int
        let accessKey: String
        let thumb: Thumb
    }
    
    // MARK: - Thumb
    struct Thumb: Codable {
        let width, height: Int
        let photo34, photo68, photo135, photo270: String
        let photo300, photo600, photo1200: String
    }
    
    // MARK: - Artist
    struct Artist: Codable {
        let name, domain, id: String
    }
    
    // MARK: - Profile
    struct Profile: Codable {
        let id: Int
    }
    
    // MARK: - OnlineInfo
    struct OnlineInfo: Codable {
        let visible: Bool
        let lastSeen: Int
        let isOnline: Bool
        let appID: Int
        let isMobile: Bool
    }
}
