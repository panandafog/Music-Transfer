//
//  SharedTrackServerModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

struct SharedTrackServerModel: Codable {
    
    let id: Int?
    let title: String
    var spotifyID, lastFmID, vkID, vkOwnerID: String?
    let artists: [String]
    let duration: Int?
    
    var servicesData: [SharedServicesData] {
        var data: [SharedServicesData] = []
        
        if let spotifyID = spotifyID {
            data.append(.spotify(spotifyID))
        }
        
        if let lastFmID = lastFmID {
            data.append(.lastFM(lastFmID))
        }
        
        if let vkID = vkID, let vkOwnerID = vkOwnerID {
            data.append(.vk(.init(id: vkID, ownerID: vkOwnerID)))
        }
        
        return data
    }
}

extension SharedTrackServerModel {
    
    var clientModel: SharedTrack {
        SharedTrack(
            serverID: id,
            artists: artists,
            title: title,
            duration: duration,
            servicesData: servicesData
        )
    }
    
    init(clientModel: SharedTrack) {
        id = clientModel.serverID
        title = clientModel.title
        artists = clientModel.artists
        duration = clientModel.duration
        
        clientModel.servicesData.forEach { serviceData in
            switch serviceData {
            case .lastFM(let id):
                lastFmID = id
            case .spotify(let id):
                spotifyID = id
            case .vk(let vkTrackData):
                vkID = vkTrackData.id
                vkOwnerID = vkTrackData.ownerID
            }
        }
    }
}

