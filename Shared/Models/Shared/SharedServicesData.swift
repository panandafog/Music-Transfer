//
//  SharedServicesData.swift
//  Music Transfer
//
//  Created by panandafog on 29.01.2022.
//

enum SharedServicesData {
    
    case vk(VKTrackData)
    case spotify(String)
    case lastFM(String)
}

extension SharedServicesData {
    
    struct VKTrackData {
        let id: String
        let ownerID: String
    }
}
