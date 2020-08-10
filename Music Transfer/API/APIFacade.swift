//
//  APIFacade.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

protocol APIFacade {
    static var authorizationUrl: URL? { get }
    func authorize()
    var isAuthorised: Bool { get }
    var apiName: String { get }
}
