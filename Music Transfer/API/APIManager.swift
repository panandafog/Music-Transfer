//
//  APIManager.swift
//  Music Transfer
//
//  Created by panandafog on 10.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Combine
import SwiftUI

class APIManager: ObservableObject {

    static var shared: APIManager = {
        let instance = APIManager()
        return instance
    }()

    private init() {}

    var facades: [APIFacade] = [SpotifyFacade.shared, VKFacade.shared]
    let objectWillChange = ObservableObjectPublisher()
}
