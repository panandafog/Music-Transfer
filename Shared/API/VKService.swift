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
    static var authorizationUrl: URL?
    
    static let authorizationRedirectUrl = "https://oauth.vk.com/blank.html"
    
    private static let v = "5.116"
    private static let lang = "en"
    private static let stateLength = 100
    
    static var state = randomString(length: stateLength)
    
    static var baseURL: URLComponents {
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "api.vk.com"
        return tmp
    }
    
    static var shared: VKService = {
        let instance = VKService()
        return instance
    }()
    
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
    
    let apiName = "VK"
    
    var tokensInfo: TokensInfo?
    
    // MARK: TokensInfo
    struct TokensInfo: Decodable {
        let access_token: String
        let expires_in: Int
        let user_id: Int
    }
    
    // MARK: ErrorInfo
    struct ErrorInfo: Decodable {
        let error: String
        let error_description: String
    }
    
    // MARK: UserInfo
    struct UserInfo: Codable {
        let id: Int
        let first_name, last_name: String
        let is_closed: Bool
    }
    
    var savedTracks = [SharedTrack]()
    
    var loginViewModel: LoginViewModel?
    var captchaViewModel: CaptchaViewModel?
    
    // MARK: authorize
    
    func authorize() -> AnyView {
        let model = LoginViewModel(twoFactor: false,
                                   captcha: nil,
                                   completion: requestTokens(username:password:code:captcha:))
        self.loginViewModel = model
        return AnyView(LoginView(model: model))
    }
    
    private let searchAttemptCount = 2
    private let searchReattemptDelay: UInt32 = 1000000
    private let requestRepeatDelay: UInt32 = 1000000
    private let addingErrorDataString = "{\"response\":0}"
    
    private var progressViewModel: TransferState {
        TransferState.shared
    }
    
    private init() {
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
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    // MARK: requestTokens
    func requestTokens(username: String, password: String, code: String?, captcha: Captcha.Solved?) {
#if os(macOS)
        DispatchQueue.main.async {
            TransferState.shared.operationInProgress = true
        }
#endif
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "oauth.vk.com"
        tmp.path = "/token"
        tmp.queryItems = [
            URLQueryItem(name: "grant_type", value: "password"),
            URLQueryItem(name: "client_id", value: String(VKKeys.client_id)),
            URLQueryItem(name: "client_secret", value: VKKeys.client_secret),
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: password),
            URLQueryItem(name: "v", value: VKService.v),
            URLQueryItem(name: "lang", value: VKService.lang),
            URLQueryItem(name: "scope", value: "all"),
            URLQueryItem(name: "device_id", value: VKService.randomString(length: 16))
        ]
        if code != nil {
            tmp.queryItems?.append(URLQueryItem(name: "code", value: code!))
        }
        if captcha != nil {
            tmp.queryItems?.append(URLQueryItem(name: "captcha_sid",
                                                value: captcha!.sid
                                               ))
            tmp.queryItems?.append(URLQueryItem(name: "captcha_key",
                                                value: captcha!.key
                                               ))
        }
        let url = tmp.url
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard error == nil else {
                sleep(failedRequestReattemptDelay)
                self.requestTokens(username: username, password: password, code: code, captcha: captcha)
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    TransferState.shared.operationInProgress = false
                }
                return
            }
            
            let tokensInfo = try? JSONDecoder().decode(TokensInfo.self, from: data)
            
            if tokensInfo != nil {
                
                guard let tokensInfo = tokensInfo else {
                    DispatchQueue.main.async {
                        TransferState.shared.operationInProgress = false
                    }
                    return
                }
                
                self.tokensInfo = tokensInfo
                
                let defaults = UserDefaults.standard
                defaults.setValue(tokensInfo.access_token, forKey: "vk_access_token")
                defaults.setValue(tokensInfo.expires_in, forKey: "vk_token_expires_in")
                defaults.setValue(tokensInfo.user_id, forKey: "vk_user_id")
                
                DispatchQueue.main.async {
                    self.loginViewModel?.shouldDismissView = true
                }
                
                self.isAuthorised = true
                
            } else {
                
                let twoFactorError = try? JSONDecoder().decode(VKErrors.Need2FactorError.self, from: data)
                
                if twoFactorError != nil && twoFactorError!.validate() {
                    DispatchQueue.main.async {
                        self.loginViewModel?.twoFactor = true
                        self.loginViewModel?.captcha = captcha
                    }
                } else {
                    let capthcaError = try? JSONDecoder().decode(VKCaptcha.ErrorMessage.self, from: data)
                    if capthcaError != nil {
                        
                        let captcha = Captcha(errorMessage: capthcaError!, solveCompletion: {(_ solvedCaptcha: Captcha.Solved) in
                            self.requestTokens(username: username, password: password, code: code, captcha: solvedCaptcha)
                        })
                        TransferState.shared.captcha = captcha
                        
                    } else {
                        let commonError = try? JSONDecoder().decode(VKErrors.CommonError.self, from: data)
                        
                        if commonError != nil && commonError!.isWrongCredentialsError() {
                            DispatchQueue.main.async {
                                self.loginViewModel?.twoFactor = code != nil
                                self.loginViewModel?.captcha = captcha
                            }
                        } else {
                            print("unknown error")
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    // MARK: getSavedTracks
    func getSavedTracks() {
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
        
        requestTracks(offset: 0, completion: {
            DispatchQueue.main.async {
                self.progressViewModel.off()
                TransferState.shared.operationInProgress = false
#if os(macOS)
                NSApp.requestUserAttention(.informationalRequest)
#else
                print("а это вообще можно сделать?")
#endif
            }
        })
    }
    
    // MARK: requestTracks
    private func requestTracks(offset: Int, completion: @escaping (() -> Void)) {
        let count = 5000
        
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        
        var tmp = VKService.baseURL
        tmp.path = "/method/audio.get"
        tmp.queryItems = [
            URLQueryItem(name: "access_token", value: access_token),
            URLQueryItem(name: "https", value: "1"),
            URLQueryItem(name: "extended", value: "1"),
            URLQueryItem(name: "v", value: VKService.v),
            URLQueryItem(name: "lang", value: VKService.lang),
            URLQueryItem(name: "count", value: "5000"),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue("VKAndroidApp/5.52-4543 (Android 5.1.1; SDK 22; x86_64; unknown Android SDK built for x86_64; en; 320x240)", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
            
            if let _ = error {
                sleep(failedRequestReattemptDelay)
                requestTracks(offset: offset, completion: completion)
                return
            }
            
            guard let data = data, let _ = String(data: data, encoding: .utf8) else {
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
    
    // MARK: addTracks
    func addTracks(_ tracks: [SharedTrack]) {
        DispatchQueue.main.async {
            TransferState.shared.operationInProgress = true
        }
        
        var reversedTracks = tracks
        reversedTracks.reverse()
        var tmpTracks = reversedTracks
        var foundTracks = [[VKSavedTracks.Item]]()
        var notFoundTracks = [SharedTrack]()
        var duplicates = [SharedTrack]()
        
        DispatchQueue.main.async {
            self.progressViewModel.determinate = true
            self.progressViewModel.progressPercentage = 0.0
            self.progressViewModel.processName = "Searching tracks in \(self.apiName)"
            self.progressViewModel.active = true
        }
        
        searchTracks(tmpTracks, attempt: 0, own: false, captcha: nil,
                     completion: { (currentFoundTracks: [VKSavedTracks.Item]) in
            tmpTracks.remove(at: 0)
            foundTracks.append(currentFoundTracks)
            print(foundTracks.count)
            
            DispatchQueue.main.async {
                self.progressViewModel.progressPercentage
                = Double(tracks.count - tmpTracks.count) / Double(tracks.count) * 100.0
            }
        },
                     finalCompletion: {
            if reversedTracks.count > 500 {
                DispatchQueue.main.async {
                    self.progressViewModel.progressPercentage = 0.0
                    self.progressViewModel.determinate = false
                    self.progressViewModel.processName = "Processing search results"
                    self.progressViewModel.active = true
                }
            }
            
            let filtered = self.filterTracks(commonTracks: reversedTracks, currentTracks: foundTracks)
            notFoundTracks.append(contentsOf: filtered.notFoundTracks)
            duplicates.append(contentsOf: filtered.duplicates)
            
            DispatchQueue.main.async {
                self.progressViewModel.determinate = true
                self.progressViewModel.progressPercentage = 0.0
                self.progressViewModel.processName = "Adding tracks to \(self.apiName)"
                self.progressViewModel.active = true
            }
            
            self.likeTracks(filtered.tracksToAdd, captcha: nil, completion: {(notLikedTrack: VKSavedTracks.Item?, remaining: Int) in
                
                DispatchQueue.main.async {
                    self.progressViewModel.progressPercentage
                    = Double(filtered.tracksToAdd.count - remaining) / Double(filtered.tracksToAdd.count) * 100
                }
                
                guard let notLikedTrack = notLikedTrack else {
                    return
                }
                notFoundTracks.append(SharedTrack(from: notLikedTrack))
                
            }, finalCompletion: {
                
                DispatchQueue.main.async {
                    self.progressViewModel.off()
                }
                
                if !notFoundTracks.isEmpty {
#if os(macOS)
                    TracksTableViewDelegate.shared.open(tracks: notFoundTracks, name: "Not found tracks")
#else
                    print("сделать таблички")
#endif
                }
                if !duplicates.isEmpty {
#if os(macOS)
                    TracksTableViewDelegate.shared.open(tracks: duplicates, name: "Duplicates")
#else
                    print("сделать таблички")
#endif
                }
                self.getSavedTracks()
            })
        })
    }
    
    // MARK: deleteAllTracks
    func deleteAllTracks() {
        DispatchQueue.main.async {
            TransferState.shared.operationInProgress = true
        }
        
        DispatchQueue.main.async {
            self.progressViewModel.off()
            self.progressViewModel.processName = "Deleting tracks from \(self.apiName)"
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
    
    // MARK: synchroniseTracks
    func synchroniseTracks(_ tracksToAdd: [SharedTrack]) {
        DispatchQueue.main.async {
            TransferState.shared.operationInProgress = true
            self.progressViewModel.off()
            self.progressViewModel.determinate = false
            self.progressViewModel.processName = "Looking for already added tracks"
            self.progressViewModel.active = true
        }
        
        var filteredTracks = [SharedTrack]()
        for index in 0 ..< tracksToAdd.count {
            var contains = false
            savedTracks.forEach({
                if $0 ~= tracksToAdd[index] {
                    contains = true
                }
            })
            if !contains {
                filteredTracks.append(tracksToAdd[index])
            }
        }
        addTracks(filteredTracks)
    }
    
    // MARK: searchTracks
    private func searchTracks(_ tracks: [SharedTrack],
                              attempt: Int,
                              own: Bool,
                              captcha: Captcha.Solved?,
                              completion: @escaping ((_ foundTracks: [VKSavedTracks.Item]) -> Void),
                              finalCompletion: @escaping (() -> Void)) {
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
            URLQueryItem(name: "v", value: VKService.v),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "auto_complete", value: "0"),
            URLQueryItem(name: "lyrics", value: "0"),
            URLQueryItem(name: "performer_only", value: "0"),
            URLQueryItem(name: "sort", value: "2"),
            URLQueryItem(name: "search_own", value: search_own),
            URLQueryItem(name: "offset", value: "0"),
            URLQueryItem(name: "count", value: "10")
        ]
        
        if captcha != nil {
            tmp.queryItems?.append(URLQueryItem(name: "captcha_sid",
                                                value: captcha!.sid
                                               ))
            tmp.queryItems?.append(URLQueryItem(name: "captcha_key",
                                                value: captcha!.key
                                               ))
        }
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue("VKAndroidApp/5.52-4543 (Android 5.1.1; SDK 22; x86_64; unknown Android SDK built for x86_64; en; 320x240)", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
            
            guard error == nil else {
                sleep(failedRequestReattemptDelay)
                searchTracks(tracks, attempt: attempt, own: own, captcha: nil, completion: completion, finalCompletion: finalCompletion)
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }
            
            let tracksList = try? JSONDecoder().decode(VKSavedTracks.TracksList.self, from: data)
            
            if tracksList != nil {
                if tracksList!.response.items.isEmpty && attempt < searchAttemptCount {
                    usleep(searchReattemptDelay)
                    searchTracks(tracks, attempt: attempt + 1, own: own, captcha: nil, completion: completion, finalCompletion: finalCompletion)
                } else {
                    completion(tracksList!.response.items)
                    var remaining = tracks
                    remaining.remove(at: 0)
                    usleep(requestRepeatDelay)
                    searchTracks(remaining, attempt: 0, own: own, captcha: nil, completion: completion, finalCompletion: finalCompletion)
                }
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    
                    let error = try? JSONDecoder().decode(VKCaptcha.ErrorMessage.self, from: data)
                    if error != nil {
                        
                        let captcha = Captcha(errorMessage: error!, solveCompletion: {(_ solvedCaptcha: Captcha.Solved) in
                            self.searchTracks(tracks, attempt: attempt, own: own, captcha: solvedCaptcha, completion: completion, finalCompletion: finalCompletion)
                        })
                        TransferState.shared.captcha = captcha
                        
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
    
    // MARK: filterTracks
    private func filterTracks(commonTracks: [SharedTrack], currentTracks: [[VKSavedTracks.Item]]) -> (tracksToAdd: [VKSavedTracks.Item], notFoundTracks: [SharedTrack], duplicates: [SharedTrack]) {
        var tracksToAdd = [VKSavedTracks.Item]()
        var notFoundTracks = [SharedTrack]()
        var duplicates = [SharedTrack]()
        
        if !commonTracks.isEmpty {
            for index in 0...commonTracks.count - 1 {
                if !currentTracks[index].isEmpty {
                    var chosenTrack: VKSavedTracks.Item? = nil
                    for foundTrack in currentTracks[index] {
                        if SharedTrack(from: foundTrack) == commonTracks[index] {
                            chosenTrack = foundTrack
                            break
                        }
                    }
                    
                    if chosenTrack != nil {
                        
                        var isDuplicate = false
                        
                        // Search for duplicates in saved tracks
                        
                        for track in savedTracks {
                            if track ~= SharedTrack(from: chosenTrack!) {
                                isDuplicate = true
                                break
                            }
                        }
                        
                        if !isDuplicate {
                            
                            // Search for duplicates in added tracks
                            
                            for track in tracksToAdd {
                                if SharedTrack(from: chosenTrack!) ~= SharedTrack(from: track) {
                                    isDuplicate = true
                                    break
                                }
                            }
                        }
                        if !isDuplicate {
                            tracksToAdd.append(chosenTrack!)
                        } else {
                            duplicates.append(commonTracks[index])
                        }
                    } else {
                        notFoundTracks.append(commonTracks[index])
                    }
                } else {
                    notFoundTracks.append(commonTracks[index])
                }
            }
        }
        return (tracksToAdd, notFoundTracks, duplicates)
    }
    
    // MARK: likeTracks
    private func likeTracks(_ tracks: [VKSavedTracks.Item],
                            captcha: Captcha.Solved?,
                            completion: @escaping ((_ notLikedTrack: VKSavedTracks.Item?,
                                                    _ remaining: Int) -> Void),
                            finalCompletion: @escaping (() -> Void)) {
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
            URLQueryItem(name: "v", value: VKService.v),
            URLQueryItem(name: "audio_id", value: String(tracks[0].id)),
            URLQueryItem(name: "owner_id", value: String(tracks[0].owner_id))
        ]
        
        if captcha != nil {
            tmp.queryItems?.append(URLQueryItem(name: "captcha_sid",
                                                value: captcha!.sid
                                               ))
            tmp.queryItems?.append(URLQueryItem(name: "captcha_key",
                                                value: captcha!.key
                                               ))
        }
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue("VKAndroidApp/5.52-4543 (Android 5.1.1; SDK 22; x86_64; unknown Android SDK built for x86_64; en; 320x240)", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
            
            guard error == nil else {
                sleep(failedRequestReattemptDelay)
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
                if let httpResponse = response as? HTTPURLResponse {
                    let error = try? JSONDecoder().decode(VKCaptcha.ErrorMessage.self, from: data)
                    if error != nil {
                        
                        let captcha = Captcha(errorMessage: error!, solveCompletion: {(_ solvedCaptcha: Captcha.Solved) in
                            self.likeTracks(tracks, captcha: solvedCaptcha, completion: completion, finalCompletion: finalCompletion)
                        })
                        TransferState.shared.captcha = captcha
                        
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
    
    // MARK: deleteTrack
    private func deleteTracks(_ tracks: [SharedTrack],
                              captcha: Captcha.Solved?,
                              completion: @escaping ((_ remaining: Int) -> Void),
                              finalCompletion: @escaping (() -> Void)) {
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        
        guard !tracks.isEmpty else {
            finalCompletion()
            return
        }
        
//        guard let ownerID = tracks[0].ownerID else {
//            var remainingTracks = tracks
//            remainingTracks.remove(at: 0)
//            completion(remainingTracks.count)
//            deleteTracks(remainingTracks, captcha: nil, completion: completion, finalCompletion: finalCompletion)
//            return
//        }
        
        var tmp = VKService.baseURL
        tmp.path = "/method/audio.delete"
        tmp.queryItems = [
            URLQueryItem(name: "access_token", value: access_token),
            URLQueryItem(name: "v", value: VKService.v),
            URLQueryItem(name: "audio_id", value: String(tracks[0].id)),
//            URLQueryItem(name: "owner_id", value: String(ownerID))
        ]
        
        if captcha != nil {
            tmp.queryItems?.append(URLQueryItem(name: "captcha_sid",
                                                value: captcha!.sid
                                               ))
            tmp.queryItems?.append(URLQueryItem(name: "captcha_key",
                                                value: captcha!.key
                                               ))
        }
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue("VKAndroidApp/5.52-4543 (Android 5.1.1; SDK 22; x86_64; unknown Android SDK built for x86_64; en; 320x240)", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
            
            guard error == nil else {
                sleep(failedRequestReattemptDelay)
                deleteTracks(tracks, captcha: captcha, completion: completion, finalCompletion: finalCompletion)
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
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
                if let httpResponse = response as? HTTPURLResponse {
                    let error = try? JSONDecoder().decode(VKCaptcha.ErrorMessage.self, from: data)
                    if error != nil {
                        
                        let captcha = Captcha(errorMessage: error!, solveCompletion: {(_ solvedCaptcha: Captcha.Solved) in
                            self.deleteTracks(tracks, captcha: solvedCaptcha, completion: completion, finalCompletion: finalCompletion)
                        })
                        TransferState.shared.captcha = captcha
                        
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
