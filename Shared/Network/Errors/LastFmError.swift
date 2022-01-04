//
//  LastFmError.swift
//  Music Transfer
//
//  Created by panandafog on 03.01.2022.
//

struct LastFmError: Error {
    
    let code: Int
    let message: String
}

extension LastFmError: Codable {
    
    enum CodingKeys: String, CodingKey {
        case code = "error"
        case message = "message"
    }
}
