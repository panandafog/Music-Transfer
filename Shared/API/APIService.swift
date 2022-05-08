//
//  APIService.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

protocol APIService: ShowingAlerts {
    
    static var apiName: String { get }
    
    var isAuthorised: Bool { get }
    var showingAuthorization: Bool { get set }
    var showingSignUp: Bool { get set }
    var showingEmailConfirmation: Bool { get set }
    var gotTracks: Bool { get }
    var refreshing: Bool { get }
    
    var savedTracks: [SharedTrack] { get }
    
    func getSavedTracks()
    func deleteAllTracks()
    func logOut()
    func exportLibrary() -> String?
}

extension APIService {
    
    // MARK: - Export
    
    func exportLibrary() -> String? {
        guard gotTracks, !savedTracks.isEmpty else {
            return nil
        }
        
        return exportTracks(tracks: savedTracks)
    }
    
    private func exportTracks(tracks: [SharedTrack]) -> String {
        tracks.map {
            $0.artists.joined(separator: ", ") + " – " + $0.title
        }
        .joined(separator: "\n")
    }
}
