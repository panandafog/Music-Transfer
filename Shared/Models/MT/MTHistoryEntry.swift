//
//  MTHistoryEntry.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 16.04.2022.
//

import Foundation

struct MTHistoryEntry: Codable {
    
    let id: Int
    let started, completed: String?
    let type: MTHistoryEntryType
}
