//
//  SpotifyService.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftUI

final class SpotifyService: APIService {
    
    // MARK: - Constants
    
    static let authorizationRedirectUrl = "https://example.com/callback/"
    static let state = NSUUID().uuidString
    static let apiName = "Spotify"
    
    static let authorizationUrl: URL? = {
        
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
    }()
    
    private static let requestTokensURL: URL? = {
        
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
    }()
    
    // MARK: - Instance properties
    
    var isAuthorised = false {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    var gotTracks = false {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    var tokensAreRequested = false
    var tokensInfo: TokensInfo?
    
    var savedTracks = [SharedTrack]()
    
    private let requestRepeatDelay: UInt32 = 1_000_000
    
    private let databaseManager: DatabaseManager = DatabaseManagerImpl(configuration: .defaultConfiguration)
    
    private var progressViewModel: TransferManager {
        TransferManager.shared
    }
    
    // MARK: - Authorization methods
    
    func authorize() -> AnyView {
        AnyView(
            BrowserView<SpotifyBrowser>(
                browser: SpotifyBrowser(
                    url: SpotifyService.authorizationUrl,
                    service: self
                )
            )
        )
    }
    
    func requestTokens(code: String) {
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
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
        
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard error == nil else {
                sleep(kFailedRequestReattemptDelay)
                self.requestTokens(code: code)
                return
            }
            
            guard let data = data else {
                return
            }
            
            guard let tokensInfo = try? JSONDecoder().decode(TokensInfo.self, from: data) else {
                return
            }
            self.tokensInfo = tokensInfo
            DispatchQueue.main.async {
                TransferManager.shared.operationInProgress = false
            }
        }
        task.resume()
    }
    
    // MARK: - Tracks management methods
    
    // MARK: Saved tracks
    
    func getSavedTracks() {
        guard let tokensInfo = self.tokensInfo else {
            return
        }
        
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
        }
        
        self.gotTracks = false
        self.savedTracks = [SharedTrack]()
        
        DispatchQueue.main.async {
            self.progressViewModel.off()
            self.progressViewModel.processName = "Receiving saved tracks from \(Self.apiName)"
            self.progressViewModel.determinate = false
            self.progressViewModel.active = true
        }
        
        var queue: MTQueue<SpotifyTracksRequestTask>?
        var id = 0
        let step = 50
        var offset = 0
        
        var rec: (() -> SpotifyTracksRequestTask)?
        rec = {
            SpotifyTracksRequestTask(id: id, offset: offset, tokensInfo: tokensInfo) { result in
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
                        sleep(kFailedRequestReattemptDelay)
                        if let operation = rec?() {
                            try? queue?.addOperation(operation: operation)
                        }
                    }
                }
            }
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
                    TransferManager.shared.operationInProgress = false
                    
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
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard error == nil else {
                sleep(kFailedRequestReattemptDelay)
                self.requestTracks(offset: offset, completion: completion)
                return
            }
            
            guard let data = data else {
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
    
    // MARK: Adding tracks
    
    func addTracks(
        operation: SpotifyAddTracksOperation,
        updateHandler: @escaping TransferManager.SpotifyAddTracksOperationHandler
    ) {
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
        }
        
        operation.searchSuboperaion.started = true
        updateHandler(operation)
        
        let tracks = operation.searchSuboperaion.tracks.map { $0.trackToSearch }
        
        DispatchQueue.main.async {
            self.progressViewModel.determinate = operation.searchSuboperaion.tracks.count > 10
            self.progressViewModel.progressPercentage = 0.0
            self.progressViewModel.processName = "Searching tracks in \(Self.apiName)"
            self.progressViewModel.active = true
        }
        
        var searchedTrackIndex = 0
        searchTracks(tracks) { (foundTracks: [SpotifySearchTracks.Item]) in
            guard searchedTrackIndex < tracks.count else {
                return
            }
            
            operation.searchSuboperaion.tracks[searchedTrackIndex].foundTracks = foundTracks
            updateHandler(operation)
            
            let processedTracksCount = searchedTrackIndex + 1
            DispatchQueue.main.async {
                self.progressViewModel.progressPercentage
                = Double(processedTracksCount) / Double(tracks.count) * 100.0
            }
            
            // It means that search completed
            if processedTracksCount == tracks.count {
                
                if processedTracksCount > 1_000 {
                    DispatchQueue.main.async {
                        self.progressViewModel.progressPercentage = 0.0
                        self.progressViewModel.determinate = false
                        self.progressViewModel.processName = "Processing search results"
                        self.progressViewModel.active = true
                    }
                }
                
                let allFoundTracks = operation.searchSuboperaion.tracks.map { $0.foundTracks ?? [] }
                
                let filtered = self.filterTracks(commonTracks: tracks, currentTracks: allFoundTracks)
                DispatchQueue.main.async {
                    self.progressViewModel.progressPercentage = 0.0
                    self.progressViewModel.determinate = filtered.tracksToAdd.count > 400
                    self.progressViewModel.processName = "Adding tracks to \(Self.apiName)"
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
                
                operation.searchSuboperaion.completed = true
                operation.likeSuboperation.started = true
                operation.likeSuboperation.trackPackagesToLike = packages.map {
                    SpotifyTracksPackageToLike(
                        tracks: $0,
                        liked: false
                    )
                }
                updateHandler(operation)
                
                var packageID = 0
                self.likeTracks(
                    packages,
                    completion: { (remaining: Int) in
                        DispatchQueue.main.async {
                            self.progressViewModel.progressPercentage = Double(packages.count - remaining) / Double(packages.count) * 100
                        }
                        
                        operation.likeSuboperation.trackPackagesToLike[packageID].liked = true
                        updateHandler(operation)
                        packageID += 1
                        
                    }, finalCompletion: {
                        operation.likeSuboperation.completed = true
                        updateHandler(operation)
                        
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
                    }
                )
            }
            searchedTrackIndex += 1
        }
    }
    
    private func searchTracks(
        _ tracks: [SharedTrack],
        completion: @escaping ((_ foundTracks: [SpotifySearchTracks.Item]) -> Void),
        finalCompletion: @escaping (() -> Void) = {}
    ) {
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
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard error == nil else {
                sleep(kFailedRequestReattemptDelay)
                self.searchTracks(tracks, completion: completion, finalCompletion: finalCompletion)
                return
            }
            
            guard let data = data else {
                return
            }
            
            let tracksList = try? JSONDecoder().decode(SpotifySearchTracks.TracksList.self, from: data).tracks.items
            
            if let tracksList = tracksList {
                completion(tracksList)
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
    
    private func filterTracks(
        commonTracks: [SharedTrack],
        currentTracks: [[SpotifySearchTracks.Item]]
    ) -> (tracksToAdd: [SpotifySearchTracks.Item], notFoundTracks: [SharedTrack]) {
        var tracksToAdd = [SpotifySearchTracks.Item]()
        var notFoundTracks = [SharedTrack]()
        
        if !commonTracks.isEmpty {
            for index in 0...commonTracks.count - 1 {
                if !currentTracks[index].isEmpty {
                    var chosenTrack: SpotifySearchTracks.Item?
                    for foundTrack in currentTracks[index] {
                        if SharedTrack(from: foundTrack) == commonTracks[index] {
                            chosenTrack = foundTrack
                            break
                        }
                    }
                    
                    if let chosenTrack = chosenTrack {
                        tracksToAdd.append(chosenTrack)
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
        finalCompletion: @escaping (() -> Void)
    ) {
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
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard error == nil else {
                sleep(kFailedRequestReattemptDelay)
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
            
            guard data != nil else {
                return
            }
        }
        task.resume()
    }
    
    // MARK: Deleting tracks
    
    func deleteAllTracks() {
        guard !self.savedTracks.isEmpty else {
            return
        }
        
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
            self.progressViewModel.off()
            self.progressViewModel.processName = "Deleting tracks from \(Self.apiName)"
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
        
        self.deleteTracks(
            packages,
            completion: { (remaining: Int) in
                DispatchQueue.main.async {
                    self.progressViewModel.progressPercentage = Double(packages.count - remaining) / Double(packages.count) * 100
                }
            }, finalCompletion: {
                DispatchQueue.main.async {
                    self.progressViewModel.off()
                    TransferManager.shared.operationInProgress = false
                }
                usleep(self.requestRepeatDelay)
                self.getSavedTracks()
            }
        )
    }
    
    private func deleteTracks(
        _ packages: [[SharedTrack]],
        completion: @escaping ((_: Int) -> Void),
        finalCompletion: @escaping (() -> Void)
    ) {
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
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if error != nil {
                sleep(kFailedRequestReattemptDelay)
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
            
            guard data != nil else {
                return
            }
        }
        task.resume()
    }
}

// MARK: - Extensions

extension SpotifyService: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        self
    }
}

extension SpotifyService {
    
    struct TokensInfo: Decodable {
        let access_token: String
        let token_type: String
        let scope: String
        let expires_in: Int
        let refresh_token: String
    }
}
