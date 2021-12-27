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

import PromiseKit
import RealmSwift
import SwiftUI

final class LastFmService: APIService {
    
    static let authorizationUrl: URL? = nil
    
    static let apiName = "Last.fm"
    
    var isAuthorised: Bool {
        session != nil
    }
    
    var showingAuthorization = false {
        didSet {
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
        
        let resultHandler: (Swift.Result<LastFmAuthorizationResponse, RequestError>) -> Void = { result in
            switch result {
            case .success(let response):
                self.session = response.session
                
                DispatchQueue.main.async {
                    self.loginViewModel?.shouldDismissView = true
                }
                
                TransferManager.shared.operationInProgress = false
            case .failure(let error):
                print(error.message ?? "error")
            }
        }
        
        NetworkService.perform(request: request, completion: resultHandler)
    }
    
    private func getSignature(from queryItems: [URLQueryItem]) -> URLQueryItem {
        let md5string = queryItems.map { $0.name + ($0.value ?? "") }.sorted().joined() + LastFmKeys.sharedSecret
        
        return URLQueryItem(
            name: "api_sig",
            value: Insecure.MD5.hash(
                data: md5string.data(using: .utf8) ?? Data()
            )
                .map {
                    String(format: "%02hhx", $0)
                }
                .joined()
        )
    }
    
    func getSavedTracks() {
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
        }
        self.gotTracks = false
        self.savedTracks = [SharedTrack]()
        
        DispatchQueue.main.async {
            TransferManager.shared.off()
            TransferManager.shared.processName = "Receiving tracks from \(Self.apiName)"
            TransferManager.shared.determinate = false
            TransferManager.shared.active = true
        }
        
        let completionHandler: () -> Void = {
            DispatchQueue.main.async {
                TransferManager.shared.off()
                TransferManager.shared.operationInProgress = false
#if os(macOS)
                NSApp.requestUserAttention(.informationalRequest)
#else
                print("а это вообще можно сделать?")
#endif
            }
        }
        
        let errorHandler: (Error) -> Void = { error in
            print(error.localizedDescription)
        }
        
        var totalPages = 0
        getSavedTracksPage(page: 1)
            .done { firstPage in
                self.savedTracks.append(contentsOf: SharedTrack.makeArray(from: firstPage))
                if let total = Int(firstPage.lovedtracks.attr.totalPages) {
                    totalPages = total
                }
            }
            .catch { error in
                errorHandler(error)
            }
            .finally {
                if totalPages > 1 {
                    when(fulfilled: (2...totalPages).map { self.getSavedTracksPage(page: $0) })
                        .done { (results: [LastFmLovedTracks]) in
                            self.savedTracks.append(contentsOf: results.flatMap { SharedTrack.makeArray(from: $0) })
                        }
                        .catch { error in
                            errorHandler(error)
                        }
                        .finally {
                            self.gotTracks = true
                            completionHandler()
                        }
                } else {
                    self.gotTracks = false
                    self.savedTracks = [SharedTrack]()
                    completionHandler()
                }
            }
    }
    
    private func getSavedTracksPage(page: Int, perPage: Int? = nil) -> Promise<LastFmLovedTracks> {
        guard let session = session else {
            return Promise<LastFmLovedTracks> { seal in
                seal.reject(RequestError.unauthorized(message: nil))
            }
        }
        
        var queryItems = [
            URLQueryItem(name: "api_key", value: LastFmKeys.apiKey),
            URLQueryItem(name: "method", value: "user.getlovedtracks"),
            URLQueryItem(name: "user", value: session.name),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "page", value: String(page))
        ]
        
        if let perPage = perPage {
            queryItems.append(URLQueryItem(name: "limit", value: String(perPage)))
        }
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "ws.audioscrobbler.com"
        tmp.path = "/2.0"
        tmp.queryItems = queryItems
        
        guard let url = tmp.url else {
            return Promise<LastFmLovedTracks> { seal in
                seal.reject(RequestError.clientError(message: "Cannot make url"))
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return Promise<LastFmLovedTracks> { seal in
            let resultHandler: (Swift.Result<LastFmLovedTracks, RequestError>) -> Void = { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                    
                case .failure(let error):
                    seal.reject(error)
                }
            }
            
            NetworkService.perform(request: request, completion: resultHandler)
        }
    }
    
    func deleteAllTracks() {
    }
}
