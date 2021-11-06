//
//  VKSearchTracksSuboperation.swift.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 05.11.2021.
//

import Foundation

struct VKSearchTracksSuboperation: TransferSuboperation {
    var id: Int?
    
    var started = false
    var completed = false
    
    var tracks: [VKSearchedTrack]
}