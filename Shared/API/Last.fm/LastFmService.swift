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
            self.gotTracks = true
            
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
                            completionHandler()
                        }
                } else {
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
    
    func addTracks(
        operation: LastFmAddTracksOperation,
        updateHandler: @escaping TransferManager.LastFmAddTracksOperationHandler
    ) {
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
        }
        
        operation.searchSuboperaion.started = Date()
        updateHandler(operation)
        
        let tracks = operation.searchSuboperaion.tracks.map { $0.trackToSearch }
        
        DispatchQueue.main.async {
            TransferManager.shared.determinate = tracks.count > 10
            TransferManager.shared.progressPercentage = 0.0
            TransferManager.shared.processName = "Searching tracks in \(Self.apiName)"
            TransferManager.shared.active = true
        }
        
        var currentTrack = -1
        let tracksCount = tracks.count
        
        when(fulfilled: tracks.map { track -> Promise<LastFmTrackSearchResult> in
            currentTrack += 1
            
            DispatchQueue.main.async {
                TransferManager.shared.progressPercentage = Double(currentTrack) / Double(tracksCount) * 100.0
            }
            
            return self.searchTrack(track)
        })
            .done { (results: [LastFmTrackSearchResult]) in
                DispatchQueue.main.async {
                    TransferManager.shared.progressPercentage = 0.0
                    TransferManager.shared.determinate = false
                    TransferManager.shared.processName = "Processing search results"
                    TransferManager.shared.active = true
                }
                print("-=-=-=-\(String(describing: results))")
            }
            .catch { error in
                DispatchQueue.main.async {
                    TransferManager.shared.progressPercentage = 0.0
                    TransferManager.shared.determinate = false
                    TransferManager.shared.active = false
                }
                print(error.localizedDescription)
            }
    }
    
    private func searchTrack(_ track: SharedTrack, page: Int = 1, perPage: Int? = nil) -> Promise<LastFmTrackSearchResult> {
        var queryItems = [
            URLQueryItem(name: "api_key", value: LastFmKeys.apiKey),
            URLQueryItem(name: "method", value: "track.search"),
            URLQueryItem(name: "track", value: track.title + " " + track.strArtists()),
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
            return Promise<LastFmTrackSearchResult> { seal in
                seal.reject(RequestError.clientError(message: "Cannot make url"))
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return Promise<LastFmTrackSearchResult> { seal in
            let resultHandler: (Swift.Result<LastFmTrackSearchResult, RequestError>) -> Void = { result in
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
    
    private func likeTrack(_ track: SharedTrack) -> Promise<Void> {
        guard let session = session else {
            return Promise<Void> { seal in
                seal.reject(RequestError.unauthorized(message: nil))
            }
        }
        
        var queryItems = [
            URLQueryItem(name: "api_key", value: LastFmKeys.apiKey),
            URLQueryItem(name: "sk", value: session.key),
            URLQueryItem(name: "method", value: "track.love"),
            URLQueryItem(name: "track", value: "Herzeleid"),
            URLQueryItem(name: "artist", value: "Rammstein")
        ]
        
        queryItems.append(getSignature(from: queryItems))
        queryItems.append(URLQueryItem(name: "format", value: "json"))
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "ws.audioscrobbler.com"
        tmp.path = "/2.0"
        tmp.queryItems = queryItems
        
        guard let url = tmp.url else {
            return Promise<Void> { seal in
                seal.reject(RequestError.clientError(message: "Cannot make url"))
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        return Promise<Void> { seal in
            let resultHandler: (RequestError?) -> Void = { error in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
            }
            
            NetworkService.perform(request: request, completion: resultHandler)
        }
    }
    
    func deleteAllTracks() {
    }
}
