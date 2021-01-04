//
//  SpotifyFacade.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation
import SwiftUI

final class SpotifyFacade: APIFacade {
    
    static let authorizationRedirectUrl = "https://example.com/callback/"
    static var state = randomString(length: stateLength)
    
    static var authorizationUrl: URL? {
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "accounts.spotify.com"
        tmp.path = "/authorize"
        tmp.queryItems = [
            URLQueryItem(name: "client_id", value: SpotifyKeys.client_id),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: SpotifyFacade.authorizationRedirectUrl),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: "user-library-read%20user-library-modify"),
            URLQueryItem(name: "show_dialog", value: "true")
        ]
        return tmp.url
    }
    
    static var shared: SpotifyFacade = {
        let instance = SpotifyFacade()
        return instance
    }()
    
    private static let stateLength = 100
    
    private static var requestTokensURL: URL? {
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "accounts.spotify.com"
        tmp.path = "/api/token"
        tmp.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: SpotifyFacade.authorizationRedirectUrl),
            URLQueryItem(name: "state", value: state)
        ]
        return tmp.url
    }
    
    let apiName = "Spotify"
    var isAuthorised = false {
        willSet {
            DispatchQueue.main.async {
                ContentView.ContentViewModel.shared.objectWillChange.send()
            }
        }
    }
    var gotTracks = false {
        willSet {
            DispatchQueue.main.async {
                ContentView.ContentViewModel.shared.objectWillChange.send()
            }
        }
    }
    
    var tokensAreRequested = false
    var tokensInfo: TokensInfo?
    
    struct TokensInfo: Decodable {
        let access_token: String
        let token_type: String
        let scope: String
        let expires_in: Int
        let refresh_token: String
    }
    
    var savedTracks = [SharedTrack]()
    
    private let requestRepeatDelay: UInt32 = 1000000
    
    private let progressViewModel = MainProgressView.MainProgressViewModel.shared
    
    private init() {}
    
    func authorize() {
        let browserDelegate = BrowserViewDelegate.shared
        browserDelegate.openBrowser(browser: SpotifyBrowser(url: SpotifyFacade.authorizationUrl))
    }
    
    private static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    // MARK: requestTokens
    func requestTokens(code: String) {
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "accounts.spotify.com"
        tmp.path = "/api/token"
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "grant_type=" + "authorization_code" + "&" +
            "client_id=" + SpotifyKeys.client_id + "&" +
            "code=" + code + "&" +
            "redirect_uri=" + SpotifyFacade.authorizationRedirectUrl + "&" +
            "&client_secret=" + SpotifyKeys.client_secret
        
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard error == nil else {
                sleep(failedRequestReattemptDelay)
                self.requestTokens(code: code)
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }
            
            guard let tokensInfo = try? JSONDecoder().decode(TokensInfo.self, from: data) else {
                return
            }
            self.tokensInfo = tokensInfo
        }
        task.resume()
    }
    
    // MARK: getSavedTracks
    func getSavedTracks() {
        self.gotTracks = false
        self.savedTracks = [SharedTrack]()
        
        DispatchQueue.main.async {
            self.progressViewModel.off()
            self.progressViewModel.processName = "Receiving saved tracks from \(self.apiName)"
            self.progressViewModel.determinate = false
            self.progressViewModel.active = true
        }
        
        requestTracks(offset: 0, completion: {
            DispatchQueue.main.async {
                self.progressViewModel.off()
            }
        })
    }
    
    private func requestTracks(offset: Int, completion: @escaping (() -> Void)) {
        let limit = 50
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "api.spotify.com"
        tmp.path = "/v1/me/tracks"
        tmp.queryItems = [
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        
        request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard error == nil else {
                sleep(failedRequestReattemptDelay)
                self.requestTracks(offset: offset, completion: completion)
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }
            
            guard let tracksList = try? JSONDecoder().decode(SpotifySavedTracks.TracksList.self, from: data) else {
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    sleep(UInt32(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "10") ?? 10)
                    self.requestTracks(offset: offset, completion: completion)
                    return
                }
            }
            
            let tracks = SharedTrack.makeArray(from: tracksList)
            self.savedTracks.append(contentsOf: tracks)
            
            if tracksList.next != nil {
                usleep(self.requestRepeatDelay)
                self.requestTracks(offset: offset + limit, completion: completion)
            } else {
                self.gotTracks = true
                completion()
            }
        }
        task.resume()
    }
    
    // MARK: addTracks
    func addTracks(_ tracks: [SharedTrack]) {
        var tracksToAdd = tracks
        var savedTracks = [SharedTrack]()
        var globalFoundTracks = [[SpotifySearchTracks.Item]]()
        
        DispatchQueue.main.async {
            self.progressViewModel.determinate = tracks.count > 10
            self.progressViewModel.progressPercentage = 0.0
            self.progressViewModel.processName = "Searching tracks in \(self.apiName)"
            self.progressViewModel.active = true
        }
        
        searchTracks(tracks,
                     completion: { (foundTracks: [SpotifySearchTracks.Item]) in
                        let currentTrack = tracksToAdd[0]
                        savedTracks.append(currentTrack)
                        globalFoundTracks.append(foundTracks)
                        
                        DispatchQueue.main.async {
                            self.progressViewModel.progressPercentage
                                = Double(savedTracks.count) / Double(tracks.count) * 100.0
                        }
                        
                        tracksToAdd.remove(at: 0)
                        
                        if savedTracks.count == tracks.count {
                            if savedTracks.count > 1000 {
                                DispatchQueue.main.async {
                                    self.progressViewModel.progressPercentage = 0.0
                                    self.progressViewModel.determinate = false
                                    self.progressViewModel.processName = "Processing search results"
                                    self.progressViewModel.active = true
                                }
                            }
                            let filtered = self.filterTracks(commonTracks: savedTracks, currentTracks: globalFoundTracks)
                            DispatchQueue.main.async {
                                self.progressViewModel.progressPercentage = 0.0
                                self.progressViewModel.determinate = filtered.tracksToAdd.count > 400
                                self.progressViewModel.processName = "Adding tracks to \(self.apiName)"
                            }
                            
                            var packages = [[SpotifySearchTracks.Item]]()
                            
                            var package = [SpotifySearchTracks.Item]()
                            for track in filtered.tracksToAdd {
                                package.append(track)
                                if package.count == 50 {
                                    packages.append(package)
                                    package.removeAll()
                                }
                            }
                            if !package.isEmpty {
                                packages.append(package)
                            }
                            
                            self.likeTracks(packages, completion: { (remaining: Int) in
                                DispatchQueue.main.async {
                                    self.progressViewModel.progressPercentage = Double(packages.count - remaining) / Double(packages.count) * 100
                                }
                            }, finalCompletion: {
                                if !filtered.notFoundTracks.isEmpty {
                                    TracksTableViewDelegate.shared.open(tracks: filtered.notFoundTracks, name: "Not found tracks: \(filtered.notFoundTracks.count)")
                                }
                                DispatchQueue.main.async {
                                    self.progressViewModel.off()
                                }
                                usleep(self.requestRepeatDelay)
                                self.getSavedTracks()
                            })
                        }
                     })
        
    }
    
    // MARK: synchroniseTracks
    func synchroniseTracks(_ tracks: [SharedTrack]) {
        addTracks(tracks)
    }
    
    // MARK: deleteAllTracks
    func deleteAllTracks() {
        guard !self.savedTracks.isEmpty else {
            return
        }
        
        DispatchQueue.main.async {
            self.progressViewModel.off()
            self.progressViewModel.processName = "Deleting tracks from \(self.apiName)"
            self.progressViewModel.progressPercentage = 0.0
            self.progressViewModel.determinate = self.savedTracks.count > 400
            self.progressViewModel.active = true
        }
        
        var packages = [[SharedTrack]]()
        
        var package = [SharedTrack]()
        for track in savedTracks {
            package.append(track)
            if package.count == 50 {
                packages.append(package)
                package.removeAll()
            }
        }
        if !package.isEmpty {
            packages.append(package)
        }
        
        self.deleteTracks(packages, completion: { (remaining: Int) in
            DispatchQueue.main.async {
                self.progressViewModel.progressPercentage = Double(packages.count - remaining) / Double(packages.count) * 100
            }
        }, finalCompletion: {
            DispatchQueue.main.async {
                self.progressViewModel.off()
            }
            usleep(self.requestRepeatDelay)
            self.getSavedTracks()
        })
    }
    
    // MARK: searchTrack
    private func searchTracks(_ tracks: [SharedTrack],
                              completion: @escaping ((_ foundTracks: [SpotifySearchTracks.Item]) -> Void),
                              finalCompletion: @escaping (() -> Void) = {}) {
        guard !tracks.isEmpty else {
            finalCompletion()
            return
        }
        
        let track = tracks[0]
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "api.spotify.com"
        tmp.path = "/v1/search"
        tmp.queryItems = [
            URLQueryItem(name: "q", value: String(track.strArtists()) + " " + String(track.title)),
            URLQueryItem(name: "type", value: "track")
        ]
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard error == nil else {
                sleep(failedRequestReattemptDelay)
                self.searchTracks(tracks, completion: completion, finalCompletion: finalCompletion)
                return
            }
            
            guard let data = data, let _ = String(data: data, encoding: .utf8) else {
                return
            }
            
            let tracksList = try? JSONDecoder().decode(SpotifySearchTracks.TracksList.self, from: data).tracks.items
            
            if tracksList != nil {
                completion(tracksList!)
                var remaining = tracks
                remaining.remove(at: 0)
                self.searchTracks(remaining, completion: completion, finalCompletion: finalCompletion)
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 429 {
                        sleep(UInt32(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "10") ?? 10)
                        self.searchTracks(tracks, completion: completion, finalCompletion: finalCompletion)
                    }
                }
            }
        }
        task.resume()
    }
    
    // MARK: filterTracks
    private func filterTracks(commonTracks: [SharedTrack], currentTracks: [[SpotifySearchTracks.Item]]) -> (tracksToAdd: [SpotifySearchTracks.Item], notFoundTracks: [SharedTrack]) {
        var tracksToAdd = [SpotifySearchTracks.Item]()
        var notFoundTracks = [SharedTrack]()
        
        if !commonTracks.isEmpty {
            for index in 0...commonTracks.count - 1 {
                if !currentTracks[index].isEmpty {
                    var chosenTrack: SpotifySearchTracks.Item? = nil
                    for foundTrack in currentTracks[index] {
                        if SharedTrack(from: foundTrack) == commonTracks[index] {
                            chosenTrack = foundTrack
                            break
                        }
                    }
                    
                    if chosenTrack != nil {
                        tracksToAdd.append(chosenTrack!)
                    } else {
                        notFoundTracks.append(commonTracks[index])
                    }
                } else {
                    notFoundTracks.append(commonTracks[index])
                }
            }
        }
        return (tracksToAdd, notFoundTracks)
    }
    
    // MARK: likeTracks
    private func likeTracks(_ packages: [[SpotifySearchTracks.Item]],
                            completion: @escaping ((_: Int) -> Void),
                            finalCompletion: @escaping (() -> Void)) {
        guard !packages.isEmpty else {
            finalCompletion()
            return
        }
        
        let tracks = packages[0]
        
        var ids = ""
        var ind = 0
        for track in tracks {
            ind += 1
            if track.id != tracks.last?.id {
                ids += String(track.id) + ","
            } else {
                ids += String(track.id)
            }
        }
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "api.spotify.com"
        tmp.path = "/v1/me/tracks"
        tmp.queryItems = [
            URLQueryItem(name: "ids", value: String(ids))
        ]
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        
        request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard error == nil else {
                sleep(failedRequestReattemptDelay)
                self.likeTracks(packages, completion: completion, finalCompletion: finalCompletion)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    sleep(UInt32(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "10") ?? 10)
                    self.likeTracks(packages, completion: completion, finalCompletion: finalCompletion)
                    return
                } else {
                    var remaining = packages
                    remaining.remove(at: 0)
                    completion(remaining.count)
                    self.likeTracks(remaining, completion: completion, finalCompletion: finalCompletion)
                    return
                }
            }
            
            guard let data = data, let _ = String(data: data, encoding: .utf8) else {
                return
            }
        }
        task.resume()
    }
    
    // MARK: deleteTracks
    private func deleteTracks(_ packages: [[SharedTrack]],
                              completion: @escaping ((_: Int) -> Void),
                              finalCompletion: @escaping (() -> Void)) {
        guard !packages.isEmpty else {
            finalCompletion()
            return
        }
        
        let tracks = packages[0]
        
        var ids = ""
        var ind = 0
        for track in tracks {
            ind += 1
            if track.id != tracks.last?.id {
                ids += String(track.id) + ","
            } else {
                ids += String(track.id)
            }
        }
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "api.spotify.com"
        tmp.path = "/v1/me/tracks"
        tmp.queryItems = [
            URLQueryItem(name: "ids", value: String(ids))
        ]
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        
        request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                sleep(failedRequestReattemptDelay)
                self.deleteTracks(packages, completion: completion, finalCompletion: finalCompletion)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    sleep(UInt32(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "10") ?? 10)
                    self.deleteTracks(packages, completion: completion, finalCompletion: finalCompletion)
                    return
                } else {
                    var remaining = packages
                    remaining.remove(at: 0)
                    completion(remaining.count)
                    self.deleteTracks(remaining, completion: completion, finalCompletion: finalCompletion)
                    return
                }
            }
            
            guard let data = data, let _ = String(data: data, encoding: .utf8) else {
                return
            }
        }
        task.resume()
    }
}

extension SpotifyFacade: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}
