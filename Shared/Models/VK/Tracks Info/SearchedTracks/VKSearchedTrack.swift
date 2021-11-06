//
//  VKSearchedTrack.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import Foundation

struct VKSearchedTrack {
    var id: Int?
    
    var trackToSearch: SharedTrack
    var foundTracks: [VKSavedTracks.Item]?
}
