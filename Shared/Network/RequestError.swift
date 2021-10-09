//
//  RequestError.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 10.10.2021.
//

enum RequestError: Error {
    
    case unauthorized(message: String?)
    case wrongCredentials(message: String?)
    case clientError(message: String?)
    case parsingError(message: String?)
    case serverError(message: String?)
    case unknownError(message: String?)
    case loadingDefaultsError(message: String?)
    
    var message: String? {
        switch self {
        case .unauthorized(let msg):
            return msg
        case .wrongCredentials(let msg):
            return msg
        case .clientError(let msg):
            return msg
        case .parsingError(let msg):
            return msg
        case .serverError(let msg):
            return msg
        case .unknownError(let msg):
            return msg
        case .loadingDefaultsError(let msg):
            return msg
        }
    }
}
