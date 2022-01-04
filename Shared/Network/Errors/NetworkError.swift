//
//  NetworkError.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 10.10.2021.
//

struct NetworkError {
    
    let type: NetworkErrorType
    private var providedMessage: String?
    
    init(type: NetworkErrorType, message: String?) {
        self.type = type
        self.providedMessage = message
    }
}

extension NetworkError: DisplayableError {
    
    var message: String {
        providedMessage ?? type.name
    }
}
