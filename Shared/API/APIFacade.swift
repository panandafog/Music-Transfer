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
    var apiName: String { get }

    var isAuthorised: Bool { get }
    var gotTracks: Bool { get }
    var savedTracks: [SharedTrack] { get }

    func authorize() -> AnyView
    
    func getSavedTracks()
    func addTracks(_: [SharedTrack])
    func synchroniseTracks(_: [SharedTrack])
    func deleteAllTracks()
}
