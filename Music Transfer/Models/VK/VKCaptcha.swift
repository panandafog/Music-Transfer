//
//  VKCaptcha.swift
//  Music Transfer
//
//  Created by panandafog on 21.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation

enum VKCaptcha {

    // MARK: - ErrorMessage
    struct ErrorMessage: Codable {
        let error: Error
    }

    // MARK: - Error
    struct Error: Codable {
        let error_code: Int
        let error_msg: String
        let request_params: [RequestParam]
        let captcha_sid: String
        let captcha_img: String
    }

    // MARK: - RequestParam
    struct RequestParam: Codable {
        let key, value: String
    }

    // MARK: - Solved
    struct Solved {
        let captcha_sid: String
        let captcha_key: String
    }
}
