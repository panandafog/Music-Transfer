//
//  SpotifyService.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

final class SpotifyService: APIService {
    
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
            URLQueryItem(name: "redirect_uri", value: SpotifyService.authorizationRedirectUrl),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: "user-library-read%20user-library-modify"),
            URLQueryItem(name: "show_dialog", value: "true")
        ]
        return tmp.url
    }
    
    static var shared: SpotifyService = {
        let instance = SpotifyService()
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
            URLQueryItem(name: "redirect_uri", value: SpotifyService.authorizationRedirectUrl),
            URLQueryItem(name: "state", value: state)
        ]
        return tmp.url
    }
    
    let apiName = "Spotify"
    var isAuthorised = false {
        willSet {
            DispatchQueue.main.async {
                TransferState.shared.objectWillChange.send()
            }
        }
    }
    var gotTracks = false {
        willSet {
            DispatchQueue.main.async {
                TransferState.shared.objectWillChange.send()
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
    
    private let databaseManager: DatabaseManager = DatabaseManagerImpl(configuration: .defaultConfiguration)
    
    private var progressViewModel: TransferState {
        TransferState.shared
    }
    
    private init() {}
    
    // MARK: authorize
    
    func authorize() -> AnyView {
        return AnyView(
            BrowserView<SpotifyBrowser>(browser: SpotifyBrowser(url: SpotifyService.authorizationUrl))
        )
    }
    
    private static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    // MARK: requestTokens
    func requestTokens(code: String) {
        DispatchQueue.main.async {
            TransferState.shared.operationInProgress = true
        }
        
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
        "redirect_uri=" + SpotifyService.authorizationRedirectUrl + "&" +
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
            DispatchQueue.main.async {
                TransferState.shared.operationInProgress = false
            }
        }
        task.resume()
    }
    
    // MARK: getSavedTracks
    func getSavedTracks() {
        guard let tokensInfo = self.tokensInfo else {
            return
        }
        
        DispatchQueue.main.async {
            TransferState.shared.operationInProgress = true
        }
        
        self.gotTracks = false
        self.savedTracks = [SharedTrack]()
        
        DispatchQueue.main.async {
            self.progressViewModel.off()
            self.progressViewModel.processName = "Receiving saved tracks from \(self.apiName)"
            self.progressViewModel.determinate = false
            self.progressViewModel.active = true
        }
        
        var queue: MTQueue<SpotifyTracksRequestTask>? = nil
        var id = 0
        let step = 50
        var offset = 0
        
        var rec: (() -> SpotifyTracksRequestTask)? = nil
        rec = {
            SpotifyTracksRequestTask(id: id, offset: offset, tokensInfo: tokensInfo, completion: { result in
                switch result {
                case .success(let tracksData):
                    self.savedTracks.append(contentsOf: tracksData.tracks)
                    
                    if tracksData.gotNext {
                        usleep(self.requestRepeatDelay)
                        id += 1
                        offset += step
                        
                        if let operation = rec?() {
                            try? queue?.addOperation(operation: operation)
                        }
                    }
                case .failure(let error):
                    switch error {
                    case .needToWait(let seconds):
                        sleep(UInt32(seconds))
                        if let operation = rec?() {
                            try? queue?.addOperation(operation: operation)
                        }
                    case .unknown:
                        sleep(failedRequestReattemptDelay)
                        if let operation = rec?() {
                            try? queue?.addOperation(operation: operation)
                        }
                    }
                }
            })
        }
        
        guard let tmpRec = rec else { return }
        
        let operations = [
            tmpRec()
        ]
        
        queue = MTQueue(
            operations: operations,
            mode: .serial,
            completion: {
                self.gotTracks = true
                DispatchQueue.main.async {
                    self.progressViewModel.off()
                    TransferState.shared.operationInProgress = false
                    
    #if os(macOS)
                    NSApp.requestUserAttention(.informationalRequest)
    #else
                    print("а это вообще можно сделать?")
    #endif
                }
            },
            progressHandler: { percentage in
                self.progressViewModel.progressPercentage = percentage
            }
        )
        
        queue?.run()
    }
    
    private func requestTracks(offset: Int, completion: @escaping (() -> Void)) {
        let limit = 50
        
        print(offset)
        
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
    
    func addTracks(_ tracks: [SharedTrack]) {
        DispatchQueue.main.async {
            TransferState.shared.operationInProgress = true
        }
        
        let id = SpotifySearchTracksSuboperationRealm.incrementedPK()
        var searchedTracks = [SpotifySearchedTrack]()
        var tracksToSearhCounter = SpotifySearchedTrackRealm.incrementedPK()
        
        for track in tracks {
            searchedTracks.append(SpotifySearchedTrack(id: tracksToSearhCounter, trackToSearch: track, foundTracks: nil))
            tracksToSearhCounter += 1
        }
        
        var searchSuboperationModel = SpotifySearchTracksSuboperation(
            id: id,
            started: true,
            completed: false,
            tracks: searchedTracks
        )
        saveSubopertion(searchSuboperationModel)
        
        DispatchQueue.main.async {
            self.progressViewModel.determinate = tracks.count > 10
            self.progressViewModel.progressPercentage = 0.0
            self.progressViewModel.processName = "Searching tracks in \(self.apiName)"
            self.progressViewModel.active = true
        }
        
        var searchedTrackIndex = 0
        searchTracks(tracks) { (foundTracks: [SpotifySearchTracks.Item]) in
            guard searchedTrackIndex < tracks.count else {
                return
            }
            
            searchSuboperationModel.tracks[searchedTrackIndex].foundTracks = foundTracks
            self.saveSubopertion(searchSuboperationModel)
            
            let processedTracksCount = searchedTrackIndex + 1
            DispatchQueue.main.async {
                self.progressViewModel.progressPercentage
                = Double(processedTracksCount) / Double(tracks.count) * 100.0
            }
            
            // It means that search completed
            if processedTracksCount == tracks.count {
                
                if processedTracksCount > 1000 {
                    DispatchQueue.main.async {
                        self.progressViewModel.progressPercentage = 0.0
                        self.progressViewModel.determinate = false
                        self.progressViewModel.processName = "Processing search results"
                        self.progressViewModel.active = true
                    }
                }
                
                let allFoundTracks = searchSuboperationModel.tracks.map { $0.foundTracks ?? [] }
                
                let filtered = self.filterTracks(commonTracks: tracks, currentTracks: allFoundTracks)
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
                
                var likeSuboperationModel = SpotifyLikeTracksSuboperation(
                    id: SpotifyLikeTracksSuboperationRealm.incrementedPK(),
                    started: true,
                    completed: false,
                    trackPackagesToLike: packages.map {
                        SpotifyTracksPackageToLike(
                            tracks: $0,
                            liked: false
                        )
                    },
                    notFoundTracks: []
                )
                
                searchSuboperationModel.completed = true
                self.saveSubopertion(searchSuboperationModel)
                self.saveSubopertion(likeSuboperationModel)
                
                var packageID = 0
                self.likeTracks(packages, completion: { (remaining: Int) in
                    DispatchQueue.main.async {
                        self.progressViewModel.progressPercentage = Double(packages.count - remaining) / Double(packages.count) * 100
                    }
                    
                    likeSuboperationModel.trackPackagesToLike[packageID].liked = true
                    self.saveSubopertion(likeSuboperationModel)
                    packageID += 1
                }, finalCompletion: {
                    likeSuboperationModel.completed = true
                    self.saveSubopertion(likeSuboperationModel)
                    
                    if !filtered.notFoundTracks.isEmpty {
#if os(macOS)
                        TracksTableViewDelegate.shared.open(tracks: filtered.notFoundTracks, name: "Not found tracks")
#else
                        print("сделать таблички")
#endif
                    }
                    DispatchQueue.main.async {
                        self.progressViewModel.off()
                    }
                    usleep(self.requestRepeatDelay)
                    self.getSavedTracks()
                })
            }
            searchedTrackIndex += 1
        }
    }
    
    func synchroniseTracks(_ tracks: [SharedTrack]) {
        addTracks(tracks)
    }
    
    func deleteAllTracks() {
        guard !self.savedTracks.isEmpty else {
            return
        }
        
        DispatchQueue.main.async {
            TransferState.shared.operationInProgress = true
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
                TransferState.shared.operationInProgress = false
            }
            usleep(self.requestRepeatDelay)
            self.getSavedTracks()
        })
    }
    
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
    
    private func likeTracks(
        _ packages: [[SpotifySearchTracks.Item]],
        completion: @escaping ((_: Int) -> Void),
        finalCompletion: @escaping (() -> Void))
    {
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
    
    // MARK: - Database methods
    
    private func saveSubopertion(_ suboperation: SpotifySearchTracksSuboperation) {
        databaseManager.write([
            SpotifySearchTracksSuboperationRealm(suboperation)
        ])
    }
    
    private func saveSubopertion(_ suboperation: SpotifyLikeTracksSuboperation) {
        databaseManager.write([
            SpotifyLikeTracksSuboperationRealm(suboperation)
        ])
    }
}

extension SpotifyService: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}