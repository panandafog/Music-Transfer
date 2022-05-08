//
//  MTService.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 13.04.2022.
//

import Foundation

import PromiseKit
import RealmSwift
import SwiftUI

class MTService: APIService {
    static var apiName: String = "Music Transfer"
    
    var isAuthorised: Bool {
        !(token == nil)
    }
    
    private var authorizationHeader: (key: String, value: String)? {
        if let token = token {
            return (key: "Authorization", value: "Bearer " + token)
        } else {
            return nil
        }
    }
    
    private let defaults = UserDefaults.standard
    private let tokenDefaultsKey = "MTAuthToken"
    
    private var token: String? {
        get {
            defaults.string(forKey: tokenDefaultsKey)
        }
        set {
            defaults.set(newValue, forKey: tokenDefaultsKey)
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    var showingAuthorization = false {
        didSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    var showingSignUp = false {
        didSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    var showingEmailConfirmation = false {
        didSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    var gotTracks = false {
        didSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    var refreshing = false {
        didSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    var savedTracks: [SharedTrack] = [] {
        didSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    private (set) lazy var loginViewModel = LoginViewModel(
        service: self,
        twoFactor: false,
        captcha: nil,
        accountCreatingEnabled: true,
        completion: authorize(username: password: unused1: unused2:)
    )
    
    private (set) lazy var signUpViewModel = SignUpViewModel(
        service: self,
        completion: signUp(username: email: password:)
    )
    
    private (set) lazy var emailConfirmationViewModel = EmailConfirmationViewModel(
        service: self,
        completion: confirmEmail(token:)
    )
    
    func getSavedTracks() {
        guard let authorizationHeader = authorizationHeader else {
            return
        }
        
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
            TransferManager.shared.progressPercentage = 0.0
            TransferManager.shared.determinate = false
            TransferManager.shared.processName = "Removing tracks from \(Self.apiName)"
            TransferManager.shared.progressActive = true
        }
        
        var tmp = URLComponents()
        tmp.scheme = "http"
        tmp.host = "localhost"
        tmp.port = 8080
        tmp.path = "/library"
        
        guard let url = tmp.url else {
            handleError(NetworkError(type: .encoding, message: "Cannot make url"))
            return
        }
        
        let resultHandler: (Swift.Result<Array<SharedTrackServerModel>, Error>, HTTPURLResponse?) -> Void = { result, _ in
            DispatchQueue.main.async {
                TransferManager.shared.operationInProgress = false
                TransferManager.shared.progressPercentage = 0.0
                TransferManager.shared.determinate = false
                TransferManager.shared.progressActive = false
            }
            switch result {
            case .success(let trackModels):
                self.savedTracks = trackModels.map { $0.clientModel }
                self.gotTracks = true
            case .failure(let error):
                DispatchQueue.main.async {
                    self.handleError(error)
                }
            }
        }
        
        NetworkClient.perform(
            request: .init(
                url: url,
                method: .get,
                body: nil,
                headers: [authorizationHeader]
            ),
            errorType: LastFmError.self,
            completion: resultHandler
        )
    }
    
    func addTracks(_ tracks: [SharedTrack]) {
        guard let authorizationHeader = authorizationHeader else {
            return
        }
        
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
            TransferManager.shared.progressPercentage = 0.0
            TransferManager.shared.determinate = false
            TransferManager.shared.processName = "Adding tracks to \(Self.apiName)"
            TransferManager.shared.progressActive = true
        }
        
        var tmp = URLComponents()
        tmp.scheme = "http"
        tmp.host = "localhost"
        tmp.port = 8080
        tmp.path = "/library"
        
        guard let url = tmp.url else {
            handleError(NetworkError(type: .encoding, message: "Cannot make url"))
            return
        }
        
        guard let bodyData = try? JSONEncoder().encode(tracks.map({ SharedTrackServerModel(clientModel: $0) })) else {
            handleError(NetworkError(type: .encoding, message: "Cannot send request"))
            return
        }
        
        let resultHandler: (Swift.Result<Array<SharedTrackServerModel>, Error>, HTTPURLResponse?) -> Void = { result, _ in
            DispatchQueue.main.async {
                TransferManager.shared.operationInProgress = false
                TransferManager.shared.progressPercentage = 0.0
                TransferManager.shared.determinate = false
                TransferManager.shared.progressActive = false
            }
            switch result {
            case .success(let newTracks):
                self.savedTracks = newTracks.map { $0.clientModel }
                self.gotTracks = true
            case .failure(let error):
                DispatchQueue.main.async {
                    self.handleError(error)
                }
            }
        }
        
        NetworkClient.perform(
            request: .init(
                url: url,
                method: .post,
                body: bodyData,
                headers: [authorizationHeader]
            ),
            errorType: LastFmError.self,
            completion: resultHandler
        )
    }
    
    func deleteAllTracks() {
        guard let authorizationHeader = authorizationHeader else {
            return
        }
        
        DispatchQueue.main.async {
            TransferManager.shared.operationInProgress = true
            TransferManager.shared.progressPercentage = 0.0
            TransferManager.shared.determinate = false
            TransferManager.shared.processName = "Removing tracks from \(Self.apiName)"
            TransferManager.shared.progressActive = true
        }
        
        var tmp = URLComponents()
        tmp.scheme = "http"
        tmp.host = "localhost"
        tmp.port = 8080
        tmp.path = "/library"
        
        guard let url = tmp.url else {
            handleError(NetworkError(type: .encoding, message: "Cannot make url"))
            return
        }
        
        let resultHandler: (Swift.Result<String, Error>, HTTPURLResponse?) -> Void = { result, _ in
            DispatchQueue.main.async {
                TransferManager.shared.operationInProgress = false
                TransferManager.shared.progressPercentage = 0.0
                TransferManager.shared.determinate = false
                TransferManager.shared.progressActive = false
            }
            switch result {
            case .success:
                self.savedTracks = []
            case .failure(let error):
                DispatchQueue.main.async {
                    self.handleError(error)
                }
            }
        }
        
        NetworkClient.perform(
            request: .init(
                url: url,
                method: .delete,
                body: nil,
                headers: [authorizationHeader]
            ),
            errorType: LastFmError.self,
            completion: resultHandler
        )
    }
    
    func logOut() {
        token = nil
        gotTracks = false
        savedTracks = []
    }
    
    // MARK: - Authorization methods
    
    private func authorize(username: String, password: String, unused1: String?, unused2: Captcha.Solved?) {
        TransferManager.shared.operationInProgress = true
        
        let queryItems = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: password),
        ]
        
        var tmp = URLComponents()
        tmp.scheme = "http"
        tmp.host = "localhost"
        tmp.port = 8080
        tmp.path = "/users/signin"
        tmp.queryItems = queryItems
        
        guard let url = tmp.url else {
            handleError(NetworkError(type: .encoding, message: "Cannot make url"))
            return
        }
        
        let resultHandler: (Swift.Result<String, Error>, HTTPURLResponse?) -> Void = { result, _ in
            TransferManager.shared.operationInProgress = false
            switch result {
            case .success(let token):
                DispatchQueue.main.async {
                    self.token = token
                    self.loginViewModel.shouldDismissView = true
                    self.showingAuthorization = false
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loginViewModel.error = error
                }
            }
        }
        
        NetworkClient.perform(
            request: .init(
                url: url,
                method: .post,
                body: nil,
                headers: []
            ),
            errorType: LastFmError.self,
            completion: resultHandler
        )
    }
    
    private func signUp(username: String, email: String, password: String) {
        TransferManager.shared.operationInProgress = true
        
        var tmp = URLComponents()
        tmp.scheme = "http"
        tmp.host = "localhost"
        tmp.port = 8080
        tmp.path = "/users/signup"
        
        let signUpRequest = SignUpRequest(
            username: username,
            password: password,
            email: email
        )
        guard let bodyData = try? JSONEncoder().encode(signUpRequest) else {
            handleError(NetworkError(type: .encoding, message: "Cannot encode request"))
            return
        }
        
        guard let url = tmp.url else {
            handleError(NetworkError(type: .encoding, message: "Cannot make url"))
            return
        }
        
        let resultHandler: (Swift.Result<Void, Error>, HTTPURLResponse?) -> Void = { result, _ in
            TransferManager.shared.operationInProgress = false
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.signUpViewModel.shouldDismissView = true
                    self.showingSignUp = false
                    self.showingEmailConfirmation = true
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.signUpViewModel.error = error
                }
            }
        }
        
        NetworkClient.perform(
            request: .init(
                url: url,
                method: .post,
                body: bodyData,
                headers: []
            ),
            errorType: LastFmError.self,
            completion: resultHandler
        )
    }
    
    private func confirmEmail(token: String) {
        TransferManager.shared.operationInProgress = true
        
        let queryItems = [
            URLQueryItem(name: "token", value: token)
        ]
        
        var tmp = URLComponents()
        tmp.scheme = "http"
        tmp.host = "localhost"
        tmp.port = 8080
        tmp.path = "/users/confirmsignup"
        tmp.queryItems = queryItems
        
        guard let url = tmp.url else {
            handleError(NetworkError(type: .encoding, message: "Cannot make url"))
            return
        }
        
        let resultHandler: (Swift.Result<Void, Error>, HTTPURLResponse?) -> Void = { result, _ in
            TransferManager.shared.operationInProgress = false
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.emailConfirmationViewModel.shouldDismissView = true
                    self.showingEmailConfirmation = false
                    self.showingAuthorization = true
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.emailConfirmationViewModel.error = error
                }
            }
        }
        
        NetworkClient.perform(
            request: .init(
                url: url,
                method: .get,
                body: nil,
                headers: []
            ),
            errorType: LastFmError.self,
            completion: resultHandler
        )
    }
    
    func saveOperation(_ operation: VKAddTracksOperationServerModel, completion: ((Swift.Result<VKAddTracksOperationServerModel, Error>) -> Void)?) {
        saveOperation(operation, type: .vk, completion: completion)
    }
    
    func saveOperation(_ operation: LastFmAddTracksOperationServerModel, completion: ((Swift.Result<LastFmAddTracksOperationServerModel, Error>) -> Void)?) {
        saveOperation(operation, type: .lastFm, completion: completion)
    }
    
    private func saveOperation<Body: Codable>(_ operation: Body, type: MTHistoryEntryType, completion: ((Swift.Result<Body, Error>) -> Void)?) {
        guard let authorizationHeader = authorizationHeader else {
            return
        }
        TransferManager.shared.uploadingHistoryInProgress = true
        
        var tmp = URLComponents()
        tmp.scheme = "http"
        tmp.host = "localhost"
        tmp.port = 8080
        tmp.path = "/" + type.endpoint + "/saveOperation"
        
        guard let bodyData = try? JSONEncoder().encode(operation) else {
            handleError(NetworkError(type: .encoding, message: "Cannot encode request"))
            return
        }
        
        guard let url = tmp.url else {
            handleError(NetworkError(type: .encoding, message: "Cannot make url"))
            return
        }
        
        let resultHandler: (Swift.Result<Body, Error>, HTTPURLResponse?) -> Void = { result, _ in
            TransferManager.shared.uploadingHistoryInProgress = false
            completion?(result)
        }
        
        NetworkClient.perform(
            request: .init(
                url: url,
                method: .post,
                body: bodyData,
                headers: [authorizationHeader]
            ),
            errorType: LastFmError.self,
            completion: resultHandler
        )
    }
    
    func getOperation(_ id: Int, completion: ((Swift.Result<VKAddTracksOperationServerModel, Error>) -> Void)?) {
        getOperation(id: id, type: .vk, completion: completion)
    }
    
    func getOperation(_ id: Int, completion: ((Swift.Result<LastFmAddTracksOperationServerModel, Error>) -> Void)?) {
        getOperation(id: id, type: .lastFm, completion: completion)
    }
    
    private func getOperation<Body: Codable>(id: Int, type: MTHistoryEntryType, completion: ((Swift.Result<Body, Error>) -> Void)?) {
        guard let authorizationHeader = authorizationHeader else {
            return
        }
        TransferManager.shared.uploadingHistoryInProgress = true
        
        let queryItems = [
            URLQueryItem(name: "id", value: String(id))
        ]
        
        var tmp = URLComponents()
        tmp.scheme = "http"
        tmp.host = "localhost"
        tmp.port = 8080
        tmp.path = "/" + type.endpoint + "/getOperation"
        tmp.queryItems = queryItems
        
        guard let url = tmp.url else {
            handleError(NetworkError(type: .encoding, message: "Cannot make url"))
            return
        }
        
        let resultHandler: (Swift.Result<Body, Error>, HTTPURLResponse?) -> Void = { result, _ in
            TransferManager.shared.uploadingHistoryInProgress = false
            completion?(result)
        }
        
        NetworkClient.perform(
            request: .init(
                url: url,
                method: .get,
                body: nil,
                headers: [authorizationHeader]
            ),
            errorType: LastFmError.self,
            completion: resultHandler
        )
    }
    
    func getHistory(_ completion: ((Swift.Result<[MTHistoryEntry], Error>) -> Void)?) {
        guard let authorizationHeader = authorizationHeader else {
            return
        }
        TransferManager.shared.uploadingHistoryInProgress = true
        
        var tmp = URLComponents()
        tmp.scheme = "http"
        tmp.host = "localhost"
        tmp.port = 8080
        tmp.path = "/operations"
        
        guard let url = tmp.url else {
            handleError(NetworkError(type: .encoding, message: "Cannot make url"))
            return
        }
        
        let resultHandler: (Swift.Result<[MTHistoryEntry], Error>, HTTPURLResponse?) -> Void = { result, _ in
            TransferManager.shared.uploadingHistoryInProgress = false
            completion?(result)
        }
        
        NetworkClient.perform(
            request: .init(
                url: url,
                method: .get,
                body: nil,
                headers: [authorizationHeader]
            ),
            errorType: LastFmError.self,
            completion: resultHandler
        )
    }
}

extension MTService {
   
    private struct SignUpRequest: Codable {
        
        let username: String
        let password: String
        let email: String
    }
}
