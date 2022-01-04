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
    
    private (set) lazy var loginViewModel = LoginViewModel(
        service: self,
        twoFactor: false,
        captcha: nil,
        completion: authorize(username:password:unused1:unused2:)
    )
    
    private (set) var session: LastFmSession?
    
    private let requestRepeatDelay: UInt32 = 1_000_000
    private let determinateElementsCount = 5
    
    // MARK: - Authorization methods
    
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
            handleError(RequestError(type: .encoding, message: "Cannot make url"))
            return
        }
        
        let resultHandler: (Swift.Result<LastFmAuthorizationResponse, Error>) -> Void = { result in
            switch result {
            case .success(let response):
                self.session = response.session
                
                DispatchQueue.main.async {
                    self.loginViewModel.shouldDismissView = true
                }
                
                TransferManager.shared.operationInProgress = false
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loginViewModel.error = error
                }
            }
        }
        
        NetworkClient.perform(url: url, method: .post, body: nil, errorType: LastFmError.self, completion: resultHandler)
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
            self.handleError(error)
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
                    var pagesIterator = (2...totalPages).makeIterator()
                    let promiseGenerator = AnyIterator<Promise<LastFmLovedTracks>> {
                        guard let page = pagesIterator.next() else {
                            return nil
                        }
                        return self.getSavedTracksPage(page: page)
                    }
                    
                    when(
                        fulfilled: promiseGenerator,
                        concurrently: 1
                    )
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
                seal.reject(RequestError(type: .unauthorized, message: nil))
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
                seal.reject(RequestError(type: .encoding, message: "Cannot make url"))
            }
        }
        
        return Promise<LastFmLovedTracks> { seal in
            let resultHandler: (Swift.Result<LastFmLovedTracks, Error>) -> Void = { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                    
                case .failure(let error):
                    seal.reject(error)
                }
            }
            NetworkClient.perform(url: url, method: .get, body: nil, errorType: LastFmError.self, completion: resultHandler)
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
        
        var currentTrack = 0
        let tracksCount = tracks.count
        var tracksIterator = tracks.makeIterator()
        
        let updateProgress: () -> Void = {
            currentTrack += 1
            
            DispatchQueue.main.async {
                TransferManager.shared.progressPercentage = Double(currentTrack) / Double(tracksCount) * 100.0
            }
        }
        
        let getSearchPromise: (SharedTrack) -> Promise<LastFmSearchedTrack> = { track in
            return Promise<LastFmSearchedTrack> { seal in
                self.searchTrack(track)
                    .done { searchResults in
                        updateProgress()
                        seal.fulfill(
                            LastFmSearchedTrack(
                                trackToSearch: track,
                                foundTracks: searchResults.results.trackmatches.track
                            )
                        )
                    }
                    .catch { error in
                        updateProgress()
                        seal.reject(error)
                    }
            }
        }
        
        let promiseGenerator = AnyIterator<Promise<LastFmSearchedTrack>> {
            guard let track = tracksIterator.next() else {
                return nil
            }
            return getSearchPromise(track)
        }
        
        when(
            fulfilled: promiseGenerator,
            concurrently: 1
        )
            .done { (results: [LastFmSearchedTrack]) in
                self.addTracks(operation: operation, updateHandler: updateHandler, searchResults: results)
            }
            .catch { error in
                DispatchQueue.main.async {
                    TransferManager.shared.progressPercentage = 0.0
                    TransferManager.shared.determinate = false
                    TransferManager.shared.active = false
                }
                self.handleError(error)
            }
    }
    
    private func addTracks(
        operation: LastFmAddTracksOperation,
        updateHandler: @escaping TransferManager.LastFmAddTracksOperationHandler,
        searchResults: [LastFmSearchedTrack]
    ) {
        if searchResults.count > 1_000 {
            DispatchQueue.main.async {
                TransferManager.shared.progressPercentage = 0.0
                TransferManager.shared.determinate = false
                TransferManager.shared.processName = "Processing search results"
                TransferManager.shared.active = true
            }
        }
        let filteredSearchResults = filterTracks(searchResults: searchResults)
        
        DispatchQueue.main.async {
            TransferManager.shared.progressPercentage = 0.0
            TransferManager.shared.determinate = filteredSearchResults.found.count > self.determinateElementsCount
            TransferManager.shared.processName = "Adding tracks to \(Self.apiName)"
        }
        
        operation.searchSuboperaion.completed = Date()
        operation.likeSuboperation.started = Date()
        operation.likeSuboperation.tracksToLike = filteredSearchResults.found.map { LastFmTrackToLike(track: $0, liked: false) }
        operation.likeSuboperation.notFoundTracks = filteredSearchResults.notFound
        updateHandler(operation)
        
        var currentTrack = 0
        let tracksCount = filteredSearchResults.found.count
        var tracksIterator = filteredSearchResults.found.makeIterator()
        
        let updateProgress: () -> Void = {
            currentTrack += 1
            DispatchQueue.main.async {
                TransferManager.shared.progressPercentage = Double(currentTrack) / Double(tracksCount) * 100.0
            }
        }
        
        let getLikePromise: (LastFmTrackSearchResult.Track) -> Promise<Void> = { track in
            return Promise<Void> { seal in
                self.loveTrack(SharedTrack(from: track), love: true)
                    .done {
                        operation.likeSuboperation.tracksToLike[currentTrack].liked = true
                        updateHandler(operation)
                        
                        updateProgress()
                        seal.fulfill(())
                    }
                    .catch { error in
                        updateProgress()
                        seal.reject(error)
                    }
            }
        }
        
        let promiseGenerator = AnyIterator<Promise<Void>> {
            guard let track = tracksIterator.next() else {
                return nil
            }
            return getLikePromise(track)
        }
        
        when(
            fulfilled: promiseGenerator,
            concurrently: 1
        )
            .done { _ in
                operation.likeSuboperation.completed = Date()
                updateHandler(operation)
                
                if !operation.likeSuboperation.notFoundTracks.isEmpty {
#if os(macOS)
                    TracksTableViewDelegate.shared.open(tracks: operation.likeSuboperation.notFoundTracks, name: "Not found tracks")
#else
                    print("сделать таблички")
#endif
                }
                DispatchQueue.main.async {
                    TransferManager.shared.off()
                }
                usleep(self.requestRepeatDelay)
                self.getSavedTracks()
            }
            .catch { error in
                self.handleError(error)
            }
    }
    
    private func filterTracks(searchResults: [LastFmSearchedTrack]) -> (found: [LastFmTrackSearchResult.Track], notFound: [SharedTrack]) {
        var found = [LastFmTrackSearchResult.Track]()
        var notFound = [SharedTrack]()
        
        searchResults.forEach { result in
            if let chosen = result.foundTracks?.first {
                found.append(chosen)
            } else {
                notFound.append(result.trackToSearch)
            }
        }
        return (found: found, notFound: notFound)
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
                seal.reject(RequestError(type: .encoding, message: "Cannot make url"))
            }
        }
        
        return Promise<LastFmTrackSearchResult> { seal in
            let resultHandler: (Swift.Result<LastFmTrackSearchResult, Error>) -> Void = { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                    
                case .failure(let error):
                    seal.reject(error)
                }
            }
            
            NetworkClient.perform(url: url, method: .get, body: nil, errorType: LastFmError.self, completion: resultHandler)
        }
    }
    
    private func loveTrack(_ track: SharedTrack, love: Bool) -> Promise<Void> {
        guard let session = session else {
            return Promise<Void> { seal in
                seal.reject(RequestError(type: .unauthorized, message: nil))
            }
        }
        
        var queryItems = [
            URLQueryItem(name: "api_key", value: LastFmKeys.apiKey),
            URLQueryItem(name: "sk", value: session.key),
            URLQueryItem(name: "method", value: love ? "track.love" : "track.unlove"),
            URLQueryItem(name: "track", value: track.title),
            URLQueryItem(name: "artist", value: track.strArtists())
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
                seal.reject(RequestError(type: .encoding, message: "Cannot make url"))
            }
        }
        
        return Promise<Void> { seal in
            let resultHandler: (Swift.Result<Void, Error>) -> Void = { result in
                switch result {
                case .success(()):
                    seal.fulfill(())
                case .failure(let error):
                    seal.reject(error)
                }
            }
            
            NetworkClient.perform(url: url, method: .post, body: nil, errorType: LastFmError.self, completion: resultHandler)
        }
    }
    
    func deleteAllTracks() {
        guard !savedTracks.isEmpty else {
            return
        }
        
        DispatchQueue.main.async {
            TransferManager.shared.progressPercentage = 0.0
            TransferManager.shared.determinate = self.savedTracks.count > self.determinateElementsCount
            TransferManager.shared.processName = "Removing tracks from \(Self.apiName)"
            TransferManager.shared.active = true
        }
        
        var currentTrack = 0
        let tracksCount = savedTracks.count
        var tracksIterator = savedTracks.makeIterator()
        
        let updateProgress: () -> Void = {
            currentTrack += 1
            DispatchQueue.main.async {
                TransferManager.shared.progressPercentage = Double(currentTrack) / Double(tracksCount) * 100.0
            }
        }
        
        let getLikePromise: (SharedTrack) -> Promise<Void> = { track in
            return Promise<Void> { seal in
                self.loveTrack(track, love: false)
                    .done {
                        updateProgress()
                        seal.fulfill(())
                    }
                    .catch { error in
                        updateProgress()
                        seal.reject(error)
                    }
            }
        }
        
        let promiseGenerator = AnyIterator<Promise<Void>> {
            guard let track = tracksIterator.next() else {
                return nil
            }
            return getLikePromise(track)
        }
        
        when(
            fulfilled: promiseGenerator,
            concurrently: 1
        )
            .done { _ in
                DispatchQueue.main.async {
                    TransferManager.shared.off()
                }
                usleep(self.requestRepeatDelay)
                self.getSavedTracks()
            }
            .catch { error in
                self.handleError(error)
            }
    }
}
