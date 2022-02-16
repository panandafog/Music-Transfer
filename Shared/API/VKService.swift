//
//  VKService.swift
//  Music Transfer
//
//  Created by panandafog on 08.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation
import SwiftUI

final class VKService: APIService {
    
    // MARK: - Constants
    
    static let authorizationRedirectUrl = "https://oauth.vk.com/blank.html"
    static let state = randomString(length: stateLength)
    static let apiName = "VK"
    
    private static let apiVersion = "5.116"
    private static let lang = "en"
    private static let stateLength = 100
    
    static var baseURL: URLComponents = {
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "api.vk.com"
        return tmp
    }()
    
    // MARK: - Instance properties
    
    var showingAuthorization = false {
        didSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    var isAuthorised = false {
        didSet {
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
    
    var tokensInfo: TokensInfo? {
        didSet {
            saveTokensInfo()
        }
    }
    
    var savedTracks = [SharedTrack]()
    
    private (set) lazy var loginViewModel = LoginViewModel(
        service: self,
        twoFactor: false,
        captcha: nil,
        completion: requestTokens(username:password:code:captcha:)
    )
    
    var captchaViewModel: CaptchaViewModel?
    
    private let databaseManager: DatabaseManager = DatabaseManagerImpl(configuration: .defaultConfiguration)
    
    private let searchAttemptCount = 2
    private let searchReattemptDelay: UInt32 = 1_000_000
    private let requestRepeatDelay: UInt32 = 1_000_000
    private let addingErrorDataString = "{\"response\":0}"
    
    private var progressViewModel: TransferManager {
        TransferManager.shared
    }
    
    // - Initialisers
    
    init() {
        let defaults = UserDefaults.standard
        
        if let access_token = defaults.string(forKey: "vk_access_token"),
           let expires_in = Int(defaults.string(forKey: "vk_token_expires_in") ?? " - "),
           let user_id = Int(defaults.string(forKey: "vk_user_id") ?? " - ") {
            self.isAuthorised = true
            self.tokensInfo = TokensInfo(access_token: access_token, expires_in: expires_in, user_id: user_id)
        } else {
            self.isAuthorised = false
        }
    }
    
    private static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in letters.randomElement() ?? "a" })
    }
    
    // MARK: - Authorization methods
    
    func requestTokens(
        username: String,
        password: String,
        code: String?,
        captcha: Captcha.Solved?
    ) { }
    
    func saveTokensInfo() {
        guard let tokensInfo = tokensInfo else {
            return
        }

        let defaults = UserDefaults.standard
        defaults.setValue(tokensInfo.access_token, forKey: "vk_access_token")
        defaults.setValue(tokensInfo.expires_in, forKey: "vk_token_expires_in")
        defaults.setValue(tokensInfo.user_id, forKey: "vk_user_id")
    }
    
    func removeTokensInfo() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "vk_access_token")
        defaults.removeObject(forKey: "vk_token_expires_in")
        defaults.removeObject(forKey: "vk_user_id")
    }
    
    func logOut() {}
    
    // MARK: - Tracks management methods
    
    // MARK: Saved tracks
    
    func getSavedTracks() {
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
        
        requestTracks(offset: 0) {
            DispatchQueue.main.async {
                self.progressViewModel.off()
                TransferManager.shared.operationInProgress = false
#if os(macOS)
                NSApp.requestUserAttention(.informationalRequest)
#else
#endif
            }
        }
    }
    
    private func requestTracks(offset: Int, completion: @escaping (() -> Void)) {
        let count = 5_000
        
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        
        var tmp = VKService.baseURL
        tmp.path = "/method/audio.get"
        tmp.queryItems = [
            URLQueryItem(name: "access_token", value: access_token),
            URLQueryItem(name: "https", value: "1"),
            URLQueryItem(name: "extended", value: "1"),
            URLQueryItem(name: "v", value: VKService.apiVersion),
            URLQueryItem(name: "lang", value: VKService.lang),
            URLQueryItem(name: "count", value: "5000"),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue(
            "VKAndroidApp/5.52-4543 (Android 5.1.1; SDK 22; x86_64; unknown Android SDK built for x86_64; en; 320x240)",
            forHTTPHeaderField: "User-Agent"
        )
        
        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            
            if error != nil {
                sleep(kFailedRequestReattemptDelay)
                requestTracks(offset: offset, completion: completion)
                return
            }
            
            guard let data = data, String(data: data, encoding: .utf8) != nil else {
                return
            }
            
            guard let tracksList = try? JSONDecoder().decode(VKSavedTracks.TracksList.self, from: data) else {
                return
            }
            
            let tracks = SharedTrack.makeArray(from: tracksList)
            self.savedTracks.append(contentsOf: tracks)
            
            if tracksList.response.count > offset + count {
                self.requestTracks(offset: offset + count, completion: completion)
            } else {
                self.gotTracks = true
                completion()
            }
        }
        task.resume()
    }
    
    // MARK: Adding tracks
    
    func addTracks(
        operation: VKAddTracksOperation,
        updateHandler: @escaping TransferManager.VKAddTracksOperationHandler
    ) {
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
        }
        
        operation.searchSuboperaion.started = Date()
        updateHandler(operation)
        
        var notFoundTracks = [SharedTrack]()
        var duplicates = [SharedTrack]()
        
        var tracksToSearch = operation.searchSuboperaion.tracks.map { $0.trackToSearch }
        let initialTracksToSearch = tracksToSearch
        
        DispatchQueue.main.async {
            self.progressViewModel.determinate = true
            self.progressViewModel.progressPercentage = 0.0
            self.progressViewModel.processName = "Searching tracks in \(Self.apiName)"
            self.progressViewModel.active = true
        }
        
        searchTracks(
            tracksToSearch,
            attempt: 0,
            own: false,
            captcha: nil,
            completion: { (currentFoundTracks: [VKSavedTracks.Item]) in
                let searchedTrackIndex = operation.searchSuboperaion.tracks.count - tracksToSearch.count
                print(searchedTrackIndex)
                
                tracksToSearch.remove(at: 0)
                
                operation.searchSuboperaion.tracks[searchedTrackIndex].foundTracks = currentFoundTracks
                updateHandler(operation)
                
                DispatchQueue.main.async {
                    self.progressViewModel.progressPercentage
                    = Double(operation.searchSuboperaion.tracks.count - tracksToSearch.count)
                    / Double(operation.searchSuboperaion.tracks.count) * 100.0
                }
            },
            finalCompletion: {
                if operation.searchSuboperaion.tracks.count > 500 {
                    DispatchQueue.main.async {
                        self.progressViewModel.progressPercentage = 0.0
                        self.progressViewModel.determinate = false
                        self.progressViewModel.processName = "Processing search results"
                        self.progressViewModel.active = true
                    }
                }
                
                let allFoundTracks = operation.searchSuboperaion.tracks.map { $0.foundTracks ?? [] }
                
                let filtered = self.filterFoundTracks(
                    initialTracks: initialTracksToSearch,
                    foundTracks: allFoundTracks
                )
                notFoundTracks.append(contentsOf: filtered.notFoundTracks)
                duplicates.append(contentsOf: filtered.duplicates)
                
                operation.searchSuboperaion.completed = Date()
                operation.likeSuboperation.started = Date()
                operation.likeSuboperation.notFoundTracks = notFoundTracks
                operation.likeSuboperation.duplicates = duplicates
                operation.likeSuboperation.tracksToLike = filtered.tracksToAdd.map {
                    VKTrackToLike(
                        track: $0,
                        liked: false
                    )
                }
                updateHandler(operation)
                
                DispatchQueue.main.async {
                    self.progressViewModel.determinate = true
                    self.progressViewModel.progressPercentage = 0.0
                    self.progressViewModel.processName = "Adding tracks to \(Self.apiName)"
                    self.progressViewModel.active = true
                }
                
                var tracksFailedToAdd = [VKSavedTracks.Item]()
                let tracksToAdd: [VKSavedTracks.Item] = filtered.tracksToAdd.reversed()
                
                self.likeTracks(
                    tracksToAdd,
                    captcha: nil,
                    completion: { (notLikedTrack: VKSavedTracks.Item?, remaining: Int) in
                        let likedTrackIndex = remaining
                        
                        DispatchQueue.main.async {
                            self.progressViewModel.progressPercentage
                            = Double(filtered.tracksToAdd.count - remaining) / Double(filtered.tracksToAdd.count) * 100
                        }
                        
                        guard let notLikedTrack = notLikedTrack else {
                            operation.likeSuboperation.tracksToLike[likedTrackIndex].liked = true
                            updateHandler(operation)
                            return
                        }
                        tracksFailedToAdd.append(notLikedTrack)
                        
                    },
                    finalCompletion: {
                        operation.likeSuboperation.completed = Date()
                        updateHandler(operation)
                        
                        DispatchQueue.main.async {
                            self.progressViewModel.off()
                        }
                        
                        self.getSavedTracks()
                    }
                )
            }
        )
    }
    
    func filterTracksToAdd(_ tracksToAdd: [SharedTrack]) -> [SharedTrack] {
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
            self.progressViewModel.off()
            self.progressViewModel.determinate = false
            self.progressViewModel.processName = "Looking for already added tracks"
            self.progressViewModel.active = true
        }
        
        var filteredTracks = [SharedTrack]()
        for index in 0 ..< tracksToAdd.count {
            var contains = false
            savedTracks.forEach {
                if $0 ~= tracksToAdd[index] {
                    contains = true
                }
            }
            
            if !contains {
                filteredTracks.append(tracksToAdd[index])
            }
        }
        return filteredTracks
    }
    
    private func searchTracks(
        _ tracks: [SharedTrack],
        attempt: Int,
        own: Bool,
        captcha: Captcha.Solved?,
        completion: @escaping ((_ foundTracks: [VKSavedTracks.Item]) -> Void),
        finalCompletion: @escaping (() -> Void)
    ) {
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        guard !tracks.isEmpty else {
            finalCompletion()
            return
        }
        
        let track = tracks[0]
        
        var search_own = "0"
        if own {
            search_own = "1"
        }
        
        let query = track.strArtists() + " - " + track.title
        
        var tmp = VKService.baseURL
        tmp.path = "/method/audio.search"
        tmp.queryItems = [
            URLQueryItem(name: "access_token", value: access_token),
            URLQueryItem(name: "v", value: VKService.apiVersion),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "auto_complete", value: "0"),
            URLQueryItem(name: "lyrics", value: "0"),
            URLQueryItem(name: "performer_only", value: "0"),
            URLQueryItem(name: "sort", value: "2"),
            URLQueryItem(name: "search_own", value: search_own),
            URLQueryItem(name: "offset", value: "0"),
            URLQueryItem(name: "count", value: "10")
        ]
        
        if let captcha = captcha {
            tmp.queryItems?.append(
                URLQueryItem(
                    name: "captcha_sid",
                    value: captcha.sid
                )
            )
            tmp.queryItems?.append(
                URLQueryItem(
                    name: "captcha_key",
                    value: captcha.key
                )
            )
        }
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue(
            "VKAndroidApp/5.52-4543 (Android 5.1.1; SDK 22; x86_64; unknown Android SDK built for x86_64; en; 320x240)",
            forHTTPHeaderField: "User-Agent"
        )
        
        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            
            guard error == nil else {
                sleep(kFailedRequestReattemptDelay)
                searchTracks(tracks, attempt: attempt, own: own, captcha: nil, completion: completion, finalCompletion: finalCompletion)
                return
            }
            
            guard let data = data, String(data: data, encoding: .utf8) != nil else {
                return
            }
            
            if let tracksList = try? JSONDecoder().decode(VKSavedTracks.TracksList.self, from: data) {
                if tracksList.response.items.isEmpty && attempt < searchAttemptCount {
                    usleep(searchReattemptDelay)
                    searchTracks(tracks, attempt: attempt + 1, own: own, captcha: nil, completion: completion, finalCompletion: finalCompletion)
                } else {
                    completion(tracksList.response.items)
                    var remaining = tracks
                    remaining.remove(at: 0)
                    usleep(requestRepeatDelay)
                    searchTracks(remaining, attempt: 0, own: own, captcha: nil, completion: completion, finalCompletion: finalCompletion)
                }
            } else {
                if (response as? HTTPURLResponse) != nil {
                    if let error = try? JSONDecoder().decode(VKCaptcha.ErrorMessage.self, from: data) {
                        let captcha = Captcha(errorMessage: error) {(_ solvedCaptcha: Captcha.Solved) in
                            self.searchTracks(
                                tracks,
                                attempt: attempt,
                                own: own,
                                captcha: solvedCaptcha,
                                completion: completion,
                                finalCompletion: finalCompletion
                            )
                        }
                        TransferManager.shared.captcha = captcha
                        
                    } else {
                        let error = try? JSONDecoder().decode(VKErrors.TooManyRequestsError.self, from: data)
                        if error != nil {
                            if error?.error.error_code == 6 { // Too many requests per second
                                sleep(2)
                                searchTracks(tracks, attempt: attempt, own: own, captcha: captcha, completion: completion, finalCompletion: finalCompletion)
                            }
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    private func filterFoundTracks(
        initialTracks: [SharedTrack],
        foundTracks: [[VKSavedTracks.Item]]
    ) -> FilterResult {
        
        var tracksToAdd = [VKSavedTracks.Item]()
        var notFoundTracks = [SharedTrack]()
        var duplicates = [SharedTrack]()
        
        if !initialTracks.isEmpty {
            for index in 0...initialTracks.count - 1 {
                if !foundTracks[index].isEmpty {
                    var chosenTrack: VKSavedTracks.Item?
                    for foundTrack in foundTracks[index] {
                        if SharedTrack(from: foundTrack) ~= initialTracks[index] {
                            chosenTrack = foundTrack
                            break
                        }
                    }
                    
                    if let chosenTrack = chosenTrack {
                        
                        var isDuplicate = false
                        
                        // Search for duplicates in saved tracks
                        
                        for track in savedTracks {
                            if track ~= SharedTrack(from: chosenTrack) {
                                isDuplicate = true
                                break
                            }
                        }
                        
                        if !isDuplicate {
                            
                            // Search for duplicates in added tracks
                            
                            for track in tracksToAdd {
                                if SharedTrack(from: chosenTrack) ~= SharedTrack(from: track) {
                                    isDuplicate = true
                                    break
                                }
                            }
                        }
                        if !isDuplicate {
                            tracksToAdd.append(chosenTrack)
                        } else {
                            duplicates.append(initialTracks[index])
                        }
                    } else {
                        notFoundTracks.append(initialTracks[index])
                    }
                } else {
                    notFoundTracks.append(initialTracks[index])
                }
            }
        }
        return FilterResult(
            tracksToAdd: tracksToAdd,
            notFoundTracks: notFoundTracks,
            duplicates: duplicates
        )
    }
    
    private func likeTracks(
        _ tracks: [VKSavedTracks.Item],
        captcha: Captcha.Solved?,
        completion: @escaping ((_ notLikedTrack: VKSavedTracks.Item?, _ remaining: Int) -> Void),
        finalCompletion: @escaping (() -> Void)
    ) {
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        
        guard !tracks.isEmpty else {
            finalCompletion()
            return
        }
        
        var tmp = VKService.baseURL
        tmp.path = "/method/audio.add"
        tmp.queryItems = [
            URLQueryItem(name: "access_token", value: access_token),
            URLQueryItem(name: "v", value: VKService.apiVersion),
            URLQueryItem(name: "audio_id", value: String(tracks[0].id)),
            URLQueryItem(name: "owner_id", value: String(tracks[0].owner_id))
        ]
        
        if let captcha = captcha {
            tmp.queryItems?.append(
                URLQueryItem(
                    name: "captcha_sid",
                    value: captcha.sid
                )
            )
            tmp.queryItems?.append(
                URLQueryItem(
                    name: "captcha_key",
                    value: captcha.key
                )
            )
        }
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue(
            "VKAndroidApp/5.52-4543 (Android 5.1.1; SDK 22; x86_64; unknown Android SDK built for x86_64; en; 320x240)",
            forHTTPHeaderField: "User-Agent"
        )
        
        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            
            guard error == nil else {
                sleep(kFailedRequestReattemptDelay)
                likeTracks(tracks, captcha: nil, completion: completion, finalCompletion: finalCompletion)
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }
            
            let addResponse = try? JSONDecoder().decode(VKAddTrack.Response.self, from: data)
            
            if addResponse != nil {
                var remainingTracks = tracks
                remainingTracks.remove(at: 0)
                
                if dataString != addingErrorDataString {
                    completion(nil, remainingTracks.count)
                } else {
                    completion(tracks[0], remainingTracks.count)
                }
                usleep(requestRepeatDelay)
                likeTracks(remainingTracks, captcha: nil, completion: completion, finalCompletion: finalCompletion)
            } else {
                if (response as? HTTPURLResponse) != nil {
                    if let error = try? JSONDecoder().decode(VKCaptcha.ErrorMessage.self, from: data) {
                        let captcha = Captcha(errorMessage: error) {(_ solvedCaptcha: Captcha.Solved) in
                            self.likeTracks(tracks, captcha: solvedCaptcha, completion: completion, finalCompletion: finalCompletion)
                        }
                        TransferManager.shared.captcha = captcha
                        
                    } else {
                        let error = try? JSONDecoder().decode(VKErrors.TooManyRequestsError.self, from: data)
                        if error != nil {
                            if error?.error.error_code == 6 { // Too many requests per second
                                sleep(1)
                                likeTracks(tracks, captcha: captcha, completion: completion, finalCompletion: finalCompletion)
                            }
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    // MARK: Deleting tracks
    
    func deleteAllTracks() {
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
        }
        
        DispatchQueue.main.async {
            self.progressViewModel.off()
            self.progressViewModel.processName = "Deleting tracks from \(Self.apiName)"
            self.progressViewModel.progressPercentage = 0.0
            self.progressViewModel.determinate = true
            self.progressViewModel.active = true
        }
        
        deleteTracks(savedTracks,
                     captcha: nil,
                     completion: {(remaining: Int) in
            DispatchQueue.main.async {
                self.progressViewModel.progressPercentage
                = Double(self.savedTracks.count - remaining) / Double(self.savedTracks.count) * 100
            }
        }, finalCompletion: {
            DispatchQueue.main.async {
                self.progressViewModel.off()
            }
            self.getSavedTracks()
        })
    }
    
    private func deleteTracks(
        _ tracks: [SharedTrack],
        captcha: Captcha.Solved?,
        completion: @escaping ((_ remaining: Int) -> Void),
        finalCompletion: @escaping (() -> Void)
    ) {
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        
        guard !tracks.isEmpty else {
            finalCompletion()
            return
        }
        let track = tracks[0]
        
        var vkTrackData: SharedServicesData.VKTrackData?
        servicesDataLoop: for serviceData in track.servicesData {
            switch serviceData {
            case .vk(let trackData):
                vkTrackData = trackData
                break servicesDataLoop
            default:
                break
            }
        }
        
        guard let ownerID = vkTrackData?.ownerID, let trackID = vkTrackData?.id else {
            var remainingTracks = tracks
            remainingTracks.remove(at: 0)
            completion(remainingTracks.count)
            deleteTracks(remainingTracks, captcha: nil, completion: completion, finalCompletion: finalCompletion)
            return
        }
        
        var tmp = VKService.baseURL
        tmp.path = "/method/audio.delete"
        tmp.queryItems = [
            URLQueryItem(name: "access_token", value: access_token),
            URLQueryItem(name: "v", value: VKService.apiVersion),
            URLQueryItem(name: "audio_id", value: trackID),
            URLQueryItem(name: "owner_id", value: ownerID)
        ]
        
        if let captcha = captcha {
            tmp.queryItems?.append(
                URLQueryItem(
                    name: "captcha_sid",
                    value: captcha.sid
                )
            )
            tmp.queryItems?.append(
                URLQueryItem(
                    name: "captcha_key",
                    value: captcha.key
                )
            )
        }
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue(
            "VKAndroidApp/5.52-4543 (Android 5.1.1; SDK 22; x86_64; unknown Android SDK built for x86_64; en; 320x240)",
            forHTTPHeaderField: "User-Agent"
        )
        
        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            
            guard error == nil else {
                sleep(kFailedRequestReattemptDelay)
                deleteTracks(tracks, captcha: captcha, completion: completion, finalCompletion: finalCompletion)
                return
            }
            
            guard let data = data, String(data: data, encoding: .utf8) != nil else {
                return
            }
            
            let addResponse = try? JSONDecoder().decode(VKAddTrack.Response.self, from: data)
            
            if addResponse != nil {
                var remainingTracks = tracks
                remainingTracks.remove(at: 0)
                completion(remainingTracks.count)
                usleep(requestRepeatDelay)
                deleteTracks(remainingTracks, captcha: nil, completion: completion, finalCompletion: finalCompletion)
            } else {
                if (response as? HTTPURLResponse) != nil {
                    if let error = try? JSONDecoder().decode(VKCaptcha.ErrorMessage.self, from: data) {
                        
                        let captcha = Captcha(errorMessage: error) {(_ solvedCaptcha: Captcha.Solved) in
                            self.deleteTracks(tracks, captcha: solvedCaptcha, completion: completion, finalCompletion: finalCompletion)
                        }
                        TransferManager.shared.captcha = captcha
                        
                    } else {
                        let error = try? JSONDecoder().decode(VKErrors.TooManyRequestsError.self, from: data)
                        if error != nil {
                            if error?.error.error_code == 6 { // Too many requests per second
                                sleep(1)
                                deleteTracks(tracks, captcha: captcha, completion: completion, finalCompletion: finalCompletion)
                            }
                        }
                    }
                }
            }
        }
        task.resume()
    }
}

// MARK: - Extensions

extension VKService {
    
    struct TokensInfo: Decodable {
        
        let access_token: String
        let expires_in: Int
        let user_id: Int
    }
    
    struct ErrorInfo: Decodable {
        
        let error: String
        let error_description: String
    }
    
    struct UserInfo: Codable {
        
        let id: Int
        let first_name, last_name: String
        let is_closed: Bool
    }
}

extension VKService {
    
    struct FilterResult {
        
        let tracksToAdd: [VKSavedTracks.Item]
        let notFoundTracks: [SharedTrack]
        let duplicates: [SharedTrack]
    }
}
