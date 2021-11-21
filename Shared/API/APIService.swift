//
//  APIService.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

protocol APIService {
    static var authorizationUrl: URL? { get }
    static var apiName: String { get }
    
    var isAuthorised: Bool { get }
    var showingAuthorization: Bool { get set }
    var gotTracks: Bool { get }
    var savedTracks: [SharedTrack] { get }
    
    func authorize() -> AnyView
    
    func getSavedTracks()
    func deleteAllTracks()
}
