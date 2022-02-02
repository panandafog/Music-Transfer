//
//  VKUser.swift
//  Music Transfer
//
//  Created by panandafog on 15.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation

// MARK: - VKUser
struct VKUser: Codable {
    
    let id: Int
    let first_name, last_name: String
    let is_closed: Bool
}
