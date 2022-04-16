//
//  VKTrackToLike.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import Foundation

struct VKTrackToLike {
    var id = NSUUID().uuidString
    var serverID: Int?
    
    var track: VKSavedTracks.Item
    var liked: Bool
}
