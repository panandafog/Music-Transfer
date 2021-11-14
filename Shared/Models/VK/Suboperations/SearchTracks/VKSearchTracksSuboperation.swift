//
//  VKSearchTracksSuboperation.swift.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import Foundation

struct VKSearchTracksSuboperation: TransferSuboperation {
    var id = NSUUID().uuidString
    
    var started: Date?
    var completed: Date?
    
    var tracks: [VKSearchedTrack]
}
