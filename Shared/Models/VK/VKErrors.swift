//
//  VKErrors.swift
//  Music Transfer
//
//  Created by panandafog on 21.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

enum VKErrors {
    
    // MARK: - TooManyRequestsError
    struct TooManyRequestsError: Codable {
        let error: Error
    }
    
    // MARK: - Need2FactorError
    struct Need2FactorError: Codable {
        let error, error_description, validation_type, validation_sid: String
        let phone_mask: String
        let redirect_uri: String
        
        func validate() -> Bool {
            error == "need_validation" &&
            error_description == "use app code" &&
            validation_type == "2fa_app"
        }
    }
    
    // MARK: - CommonError
    struct CommonError: Codable {
        let error: String
        let error_description: String
        let error_type: String
        
        func isWrongCredentialsError() -> Bool {
            error == "invalid_client" &&
            error_description == "Username or password is incorrect" &&
            error_type == "username_or_password_is_incorrect"
        }
    }
    
    // MARK: - Error
    struct Error: Codable {
        let error_code: Int
        let error_msg: String
        let request_params: [RequestParam]
    }
    
    // MARK: - RequestParam
    struct RequestParam: Codable {
        let key, value: String
    }
}
