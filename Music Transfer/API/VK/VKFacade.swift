//
//  VKFacade.swift
//  Music Transfer
//
//  Created by panandafog on 08.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation
import SwiftUI

final class VKFacade: APIFacade {
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
    
    static var shared: VKFacade = {
        let instance = VKFacade()
        return instance
    }()
    
    var isAuthorised = false {
        willSet {
            APIManager.shared.objectWillChange.send()
        }
    }
    var gotTracks = false {
        willSet {
            APIManager.shared.objectWillChange.send()
        }
    }
    
    let apiName = "VK"
    
    var tokensInfo: TokensInfo?
    
    // MARK: - TokensInfo
    struct TokensInfo: Decodable {
        let access_token: String
        let expires_in: Int
        let user_id: Int
    }
    
    // MARK: - ErrorInfo
    struct ErrorInfo: Decodable {
        let error: String
        let error_description: String
    }
    
    // MARK: - UserInfo
    struct UserInfo: Codable {
        let id: Int
        let first_name, last_name: String
        let is_closed: Bool
    }
    
    var savedTracks = [SharedTrack]()
    
    func authorize() {
        LoginViewDelegate.shared.open(twoFactor: false, captcha: nil, completion: requestTokens(username:password:code:captcha:))
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
    
    func requestTokens(username: String, password: String, code: String?, captcha: VKCaptcha.Solved?) {
        
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
            URLQueryItem(name: "v", value: VKFacade.v),
            URLQueryItem(name: "lang", value: VKFacade.lang),
            URLQueryItem(name: "scope", value: "all"),
            URLQueryItem(name: "device_id", value: VKFacade.randomString(length: 16))
        ]
        if code != nil {
            tmp.queryItems?.append(URLQueryItem(name: "code", value: code!))
        }
        if captcha != nil {
            tmp.queryItems?.append(URLQueryItem(name: "captcha_sid",
                                                value: captcha!.captcha_sid
            ))
            tmp.queryItems?.append(URLQueryItem(name: "captcha_key",
                                                value: captcha!.captcha_key
            ))
        }
        let url = tmp.url
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }
            
            print(dataString)
            
            let tokensInfo = try? JSONDecoder().decode(TokensInfo.self, from: data)
            
            if tokensInfo != nil {
                
                guard let tokensInfo = tokensInfo else {
                    return
                }
                
                self.tokensInfo = tokensInfo
                self.isAuthorised = true
                
                let defaults = UserDefaults.standard
                defaults.setValue(tokensInfo.access_token, forKey: "vk_access_token")
                defaults.setValue(tokensInfo.expires_in, forKey: "vk_token_expires_in")
                defaults.setValue(tokensInfo.user_id, forKey: "vk_user_id")
            } else {
                
                let twoFactorError = try? JSONDecoder().decode(VKErrors.Need2FactorError.self, from: data)
                
                if twoFactorError != nil && twoFactorError!.validate() {
                    LoginViewDelegate.shared.open(twoFactor: true, captcha: captcha, completion: self.requestTokens(username:password:code:captcha:))
                } else {
                    let capthcaError = try? JSONDecoder().decode(VKCaptcha.ErrorMessage.self, from: data)
                    if capthcaError != nil {
                        print(capthcaError?.error.captcha_img as Any)
                        let captchaDelegate = CaptchaViewDelegate.shared
                        captchaDelegate.open(errorMsg: capthcaError!, completion: {(_ solvedCaptcha: VKCaptcha.Solved) in
                            self.requestTokens(username: username, password: password, code: code, captcha: solvedCaptcha)
                        })
                    } else {
                        let commonError = try? JSONDecoder().decode(VKErrors.CommonError.self, from: data)
                        
                        if commonError != nil && commonError!.isWrongCredentialsError() {
                            LoginViewDelegate.shared.open(twoFactor: code != nil, captcha: captcha, completion: self.requestTokens(username:password:code:captcha:))
                        } else {
                            print("unknown error")
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    func getSavedTracks() {
        self.gotTracks = false
        self.savedTracks = [SharedTrack]()
        requestTracks(offset: 0)
    }
    
    private func requestTracks(offset: Int) {
        let count = 5000
        
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        
        var tmp = VKFacade.baseURL
        tmp.path = "/method/audio.get"
        tmp.queryItems = [
            URLQueryItem(name: "access_token", value: access_token),
            URLQueryItem(name: "https", value: "1"),
            URLQueryItem(name: "extended", value: "1"),
            URLQueryItem(name: "v", value: VKFacade.v),
            URLQueryItem(name: "lang", value: VKFacade.lang),
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
            
            if let error = error {
                print("Error took place \(error)")
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
                print(String(offset + count))
                self.requestTracks(offset: offset + count)
            } else {
                self.gotTracks = true
            }
        }
        task.resume()
    }
    
    func addTracks(_ tracks: [SharedTrack]) {
        var savedTracks = [SharedTrack]()
        for index in 0...tracks.count - 1 {
            savedTracks.append(tracks[index])
        }
        var commonTracks = savedTracks
        var globalFoundTracks = [[VKSavedTracks.Item]]()
        var notFoundTracks = [SharedTrack]()
        
        searchTrack(savedTracks, attempt: 0, own: false, captcha: nil,
                    completion: { (foundTracks: [VKSavedTracks.Item]) in
                        if foundTracks.isEmpty {
                            notFoundTracks.append(savedTracks[0])
                        }
                        savedTracks.remove(at: 0)
                        globalFoundTracks.append(foundTracks)
                        
                        print(String(savedTracks.count))
                        print(String(tracks.count))
                        print(!foundTracks.isEmpty)
                        print("––––")
                    },
                    globalCompletion: {
                        let tracksToAdd = self.filterTracks(commonTracks: commonTracks, currentTracks: globalFoundTracks)
                        self.likeTracks(tracksToAdd, captcha: nil, completion: {}, globalCompletion: {
                            TracksTableViewDelegate.shared.open(tracks: notFoundTracks, name: "Not found tracks:")
                        })
                    })
    }
    
    func synchroniseTracks(_ tracks: [SharedTrack]) {
        var filteredTracks = [SharedTrack]()
        for index in 0...29 {
            var contains = false
            savedTracks.forEach({
                if $0 ~= tracks[index] {
                    contains = true
                } else {
                    let _ = 0
                }
            })
            if !contains {
                filteredTracks.append(tracks[index])
            }
        }
        addTracks(filteredTracks)
    }
    
    private func searchTrack(_ tracks: [SharedTrack],
                             attempt: Int,
                             own: Bool,
                             captcha: VKCaptcha.Solved?,
                             completion: @escaping ((_ foundTracks: [VKSavedTracks.Item]) -> Void),
                             globalCompletion: @escaping (() -> Void)) {
        guard let access_token = self.tokensInfo?.access_token else {
            return
        }
        guard !tracks.isEmpty else {
            globalCompletion()
            return
        }
        print("attempt: \(attempt)")
        let track = tracks[0]
        
        var search_own = "0"
        if own {
            search_own = "1"
        }
        
        let query = track.strArtists() + " - " + track.title
        
        var tmp = VKFacade.baseURL
        tmp.path = "/method/audio.search"
        tmp.queryItems = [
            URLQueryItem(name: "access_token", value: access_token),
            URLQueryItem(name: "v", value: VKFacade.v),
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
                                                value: captcha!.captcha_sid
            ))
            tmp.queryItems?.append(URLQueryItem(name: "captcha_key",
                                                value: captcha!.captcha_key
            ))
        }
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue("VKAndroidApp/5.52-4543 (Android 5.1.1; SDK 22; x86_64; unknown Android SDK built for x86_64; en; 320x240)", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }
            
            let tracksList = try? JSONDecoder().decode(VKSavedTracks.TracksList.self, from: data)
            
            if tracksList != nil {
                if tracksList!.response.items.isEmpty && attempt < 5 {
                    usleep(1000000)
                    searchTrack(tracks, attempt: attempt + 1, own: own, captcha: nil, completion: completion, globalCompletion: globalCompletion)
                } else {
                    completion(tracksList!.response.items)
                    var remaining = tracks
                    remaining.remove(at: 0)
                    usleep(100000)
                    searchTrack(remaining, attempt: 0, own: own, captcha: nil, completion: completion, globalCompletion: globalCompletion)
                }
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    print(dataString)
                    
                    let error = try? JSONDecoder().decode(VKCaptcha.ErrorMessage.self, from: data)
                    if error != nil {
                        print(error?.error.captcha_img as Any)
                        let captchaDelegate = CaptchaViewDelegate.shared
                        captchaDelegate.open(errorMsg: error!, completion: {(_ solvedCaptcha: VKCaptcha.Solved) in
                            searchTrack(tracks, attempt: attempt, own: own, captcha: solvedCaptcha, completion: completion, globalCompletion: globalCompletion)
                        })
                    } else {
                        print("!!!!!!!!")
                        let error = try? JSONDecoder().decode(VKErrors.TooManyRequestsError.self, from: data)
                        if error != nil {
                            if error?.error.error_code == 6 { // Too many requests per second
                                sleep(1)
                                searchTrack(tracks, attempt: attempt, own: own, captcha: captcha, completion: completion, globalCompletion: globalCompletion)
                            }
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    private func filterTracks(commonTracks: [SharedTrack], currentTracks: [[VKSavedTracks.Item]]) -> [VKSavedTracks.Item] {
        var res = [VKSavedTracks.Item]()
        if !commonTracks.isEmpty {
            for index in 0...commonTracks.count - 1 {
                if !currentTracks[index].isEmpty {
                    res.append(currentTracks[index][0])
                }
            }
        }
        return res
    }
    
    private func likeTracks(_ tracks: [VKSavedTracks.Item],
                            captcha: VKCaptcha.Solved?,
                            completion: @escaping (() -> Void),
                            globalCompletion: @escaping (() -> Void)) {
        guard let access_token = self.tokensInfo?.access_token,
              let tokensInfo = self.tokensInfo else {
            return
        }
        
        guard !tracks.isEmpty else {
            globalCompletion()
            return
        }
        
        var tmp = VKFacade.baseURL
        tmp.path = "/method/audio.add"
        tmp.queryItems = [
            URLQueryItem(name: "access_token", value: access_token),
            URLQueryItem(name: "v", value: VKFacade.v),
            URLQueryItem(name: "audio_id", value: String(tracks[0].id)),
            //            URLQueryItem(name: "owner_id", value: String(tokensInfo.user_id))
            URLQueryItem(name: "owner_id", value: String(tracks[0].owner_id))
        ]
        
        if captcha != nil {
            tmp.queryItems?.append(URLQueryItem(name: "captcha_sid",
                                                value: captcha!.captcha_sid
            ))
            tmp.queryItems?.append(URLQueryItem(name: "captcha_key",
                                                value: captcha!.captcha_key
            ))
        }
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue("VKAndroidApp/5.52-4543 (Android 5.1.1; SDK 22; x86_64; unknown Android SDK built for x86_64; en; 320x240)", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }
            
            let addResponse = try? JSONDecoder().decode(VKAddTrack.Response.self, from: data)
            
            if addResponse != nil {
                var remainingTracks = tracks
                remainingTracks.remove(at: 0)
                completion()
                likeTracks(remainingTracks, captcha: nil, completion: completion, globalCompletion: globalCompletion)
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    print(dataString)
                    
                    let error = try? JSONDecoder().decode(VKCaptcha.ErrorMessage.self, from: data)
                    if error != nil {
                        print(error?.error.captcha_img as Any)
                        let captchaDelegate = CaptchaViewDelegate.shared
                        captchaDelegate.open(errorMsg: error!, completion: {(_ solvedCaptcha: VKCaptcha.Solved) in
                            likeTracks(tracks, captcha: solvedCaptcha, completion: completion, globalCompletion: globalCompletion)
                        })
                    } else {
                        let error = try? JSONDecoder().decode(VKErrors.TooManyRequestsError.self, from: data)
                        if error != nil {
                            if error?.error.error_code == 6 { // Too many requests per second
                                sleep(1)
                                likeTracks(tracks, captcha: captcha, completion: completion, globalCompletion: globalCompletion)
                            }
                        }
                    }
                }
            }
        }
        task.resume()
    }
}
