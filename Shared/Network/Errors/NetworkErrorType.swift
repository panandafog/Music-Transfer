//
//  NetworkErrorType.swift
//  Music Transfer
//
//  Created by panandafog on 03.01.2022.
//

enum NetworkErrorType {
    
    case unauthorized
    case wrongCredentials
    case encoding
    case decoding
    case noResponse
    case noData
    case loadingDefaults
    case invalidStatusCode(code: Int)
    case unknown
    
    var name: String {
        switch self {
        case .unauthorized:
            return "Unauthorized"
        case .wrongCredentials:
            return "Wrong credentials"
        case .encoding:
            return "Error while encoding request"
        case .decoding:
            return "Error while decoding response"
        case .noResponse:
            return "Received empty response from server"
        case .noData:
            return "Received empty data from server"
        case .loadingDefaults:
            return "Error while loading default values"
        case .invalidStatusCode(let code):
            return "Received invalid status code: \(code)"
        case .unknown:
            return "Unknown error"
        }
    }
}
