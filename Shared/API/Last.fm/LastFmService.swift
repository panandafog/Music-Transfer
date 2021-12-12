//
//  LastFmService.swift
//  Music Transfer
//
//  Created by panandafog on 12.12.2021.
//

import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG
import CryptoKit

import RealmSwift
import SwiftUI

final class LastFmService: APIService {
    
    static let authorizationUrl: URL? = nil
    
    static let apiName = "Last.fm"
    
    var isAuthorised = false
    
    var showingAuthorization = false {
        didSet {
            print("-=- last.fm showing: \(isAuthorised)")
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    var gotTracks = false
    
    var savedTracks: [SharedTrack] = []
    
    var loginViewModel: LoginViewModel?
    
    private (set) var session: LastFmSession?
    
    // MARK: - Authorization methods
    
    func authorize() -> AnyView {
        let model = LoginViewModel(
            service: self,
            twoFactor: false,
            captcha: nil,
            completion: authorize(username:password:unused1:unused2:)
        )
        loginViewModel = model
        return AnyView(LoginView(model: model))
    }
    
    private func authorize(username: String, password: String, unused1: String?, unused2: Captcha.Solved?) {
        TransferManager.shared.operationInProgress = true
        
        var queryItems = [
            URLQueryItem(name: "api_key", value: LastFmKeys.apiKey),
            URLQueryItem(name: "method", value: "auth.getMobileSession"),
            URLQueryItem(name: "password", value: password),
            URLQueryItem(name: "username", value: username)
        ]
        
        queryItems.append(getSignature(from: queryItems))
        queryItems.append(URLQueryItem(name: "format", value: "json"))
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "ws.audioscrobbler.com"
        tmp.path = "/2.0"
        tmp.queryItems = queryItems
        
        guard let url = tmp.url else {
            print("url error")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, String(data: data, encoding: .utf8) != nil else {
                TransferManager.shared.operationInProgress = false
                return
            }
            
            let response = try? JSONDecoder().decode(LastFmAuthorizationResponse.self, from: data)
            
            if response != nil {
                
                guard let response = response else {
                    TransferManager.shared.operationInProgress = false
                    return
                }
                
                self.session = response.session
                
                DispatchQueue.main.async {
                    self.loginViewModel?.shouldDismissView = true
                }
                
                self.isAuthorised = true
                TransferManager.shared.operationInProgress = false
                
            } else {
                
                print("error")
            }
        }
        task.resume()
    }
    
    func getSignature(from queryItems: [URLQueryItem]) -> URLQueryItem {
        let md5string = queryItems.map { $0.name + ($0.value ?? "") }.sorted().joined() + LastFmKeys.sharedSecret
        
        return URLQueryItem(
            name: "api_sig",
            value: Insecure.MD5.hash(
                data: md5string.data(using: .utf8) ?? Data()
            ).map {
                String(format: "%02hhx", $0)
            }.joined()
        )
    }
    
    func getSavedTracks() {
    }
    
    func deleteAllTracks() {
    }
}
