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
                APIManager.shared.objectWillChange.send()
            }
        }
    }
    var gotTracks = false {
        willSet {
            DispatchQueue.main.async {
                APIManager.shared.objectWillChange.send()
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
        
        print(url.absoluteString)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
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
        requestTracks(offset: 0)
        print(savedTracks.count)
        print()
    }
    
    private func requestTracks(offset: Int) {
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
        print("Bearer " + access_token)
        request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
                sleep(failedRequestReattemptDelay)
                self.requestTracks(offset: offset)
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }
            
            guard let tracksList = try? JSONDecoder().decode(SpotifySavedTracks.TracksList.self, from: data) else {
                return
            }
            
            let tracks = SharedTrack.makeArray(from: tracksList)
            self.savedTracks.append(contentsOf: tracks)
            
            if tracksList.next != nil {
                print(String(offset + limit))
                usleep(self.requestRepeatDelay)
                self.requestTracks(offset: offset + limit)
            } else {
                self.gotTracks = true
            }
        }
        task.resume()
    }
    
    // MARK: addTracks
    func addTracks(_ tracks: [SharedTrack]) {
        var savedTracks = [SharedTrack]()
        var globalFoundTracks = [[SpotifySearchTracks.Item]]()
        
        for track in tracks {
            let currentTrack = track
            searchTrack(currentTrack,
                        completion: { (foundTracks: [SpotifySearchTracks.Item]) in
                            savedTracks.append(currentTrack)
                            globalFoundTracks.append(foundTracks)
                            
                            print(String(savedTracks.count))
                            print(String(tracks.count))
                            print("––––")
                            
                            if savedTracks.count == tracks.count {
                                print("filter")
                                let filtered = self.filterTracks(commonTracks: savedTracks, currentTracks: globalFoundTracks)
                                if filtered.tracksToAdd.count <= 50 {
                                    self.likeTracks(filtered.tracksToAdd, completion: {})
                                } else {
                                    var package = [SpotifySearchTracks.Item]()
                                    
                                    for track in filtered.tracksToAdd {
                                        package.append(track)
                                        if package.count == 50 {
                                            self.likeTracks(package, completion: {})
                                            package.removeAll()
                                            usleep(self.requestRepeatDelay)
                                        }
                                    }
                                    if !package.isEmpty {
                                        self.likeTracks(package, completion: {})
                                    }
                                }
                                if !filtered.notFoundTracks.isEmpty {
                                    TracksTableViewDelegate.shared.open(tracks: filtered.notFoundTracks, name: "Not found tracks: \(filtered.notFoundTracks.count)")
                                }
                            }
                        })
            usleep(requestRepeatDelay)
        }
        getSavedTracks()
        print("end")
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
        
        var package = [SharedTrack]()
        
        for track in savedTracks {
            package.append(track)
            if package.count == 50 {
                deleteTracks(package, completion: {})
                package.removeAll()
                usleep(self.requestRepeatDelay)
            }
        }
        if !package.isEmpty {
            deleteTracks(package, completion: {})
        }
        
        usleep(self.requestRepeatDelay)
        self.getSavedTracks()
        print("end")
        
    }
    
    // MARK: searchTrack
    private func searchTrack(_ track: SharedTrack, completion: @escaping ((_ foundTracks: [SpotifySearchTracks.Item]) -> Void)) {
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
        print("Bearer " + access_token)
        request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
                sleep(failedRequestReattemptDelay)
                self.searchTrack(track, completion: completion)
                return
            }
            
            guard let data = data, let _ = String(data: data, encoding: .utf8) else {
                return
            }
            
            let tracksList = try? JSONDecoder().decode(SpotifySearchTracks.TracksList.self, from: data).tracks.items
            
            if tracksList != nil {
                completion(tracksList!)
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 429 {
                        print(httpResponse.value(forHTTPHeaderField: "Retry-After"))
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
    private func likeTracks(_ tracks: [SpotifySearchTracks.Item],
                            completion: @escaping (() -> Void)) {
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
        print("Bearer " + access_token)
        request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
                sleep(failedRequestReattemptDelay)
                self.likeTracks(tracks, completion: completion)
                return
            }
            
            guard let data = data, let _ = String(data: data, encoding: .utf8) else {
                return
            }
            
            completion()
        }
        task.resume()
    }
    
    // MARK: deleteTracks
    private func deleteTracks(_ tracks: [SharedTrack],
                              completion: @escaping (() -> Void)) {
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
        print("Bearer " + access_token)
        request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
                sleep(failedRequestReattemptDelay)
                self.deleteTracks(tracks, completion: completion)
                return
            }
            
            guard let data = data, let _ = String(data: data, encoding: .utf8) else {
                return
            }
            
            completion()
        }
        task.resume()
    }
}

extension SpotifyFacade: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}
