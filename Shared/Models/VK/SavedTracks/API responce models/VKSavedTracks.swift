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
    class Item: Codable {
        let artist: String
        var id: String
        let serverID: Int?
        let owner_id: Int
        let title: String
        let duration: Int
        
        enum CodingKeys: String, CodingKey {
            case artist
            case id = "aaaaaaaaa"
            case serverID = "id"
            case owner_id
            case title
            case duration
        }
        
        init(
            artist: String,
            id: String = NSUUID().uuidString,
            serverID: Int?,
            owner_id: Int,
            title: String,
            duration: Int
        ) {
            self.artist = artist
            self.id = id
            self.serverID = serverID
            self.owner_id = owner_id
            self.title = title
            self.duration = duration
        }
        
        required init(from decoder: Decoder) throws {
            id = NSUUID().uuidString
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            artist = try container.decode(String.self, forKey: .artist)
            serverID = try container.decodeIfPresent(Int.self, forKey: .serverID)
            owner_id = try container.decode(Int.self, forKey: .owner_id)
            title = try container.decode(String.self, forKey: .title)
            duration = try container.decode(Int.self, forKey: .duration)
        }
    }
    
    // MARK: - Ads
    struct Ads: Codable {
        let contentID, duration, accountAgeType, puid1: String
        let puid22: String
    }
    
    // MARK: - Album
    struct Album: Codable {
        let id: Int
        var serverID: Int?
        let title: String
        let ownerID: Int
        let accessKey: String
        let thumb: Thumb?
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
        var serverID: Int?
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
