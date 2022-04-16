//
//  MTHistoryEntryType.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 16.04.2022.
//

import Foundation

enum MTHistoryEntryType: String, Codable {
    
    case lastFm = "last_fm"
    case vk = "vk"
    
    var endpoint: String {
        switch self {
        case .lastFm:
            return "lastfm"
        case .vk:
            return "vk"
        }
    }
}
