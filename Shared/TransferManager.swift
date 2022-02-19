//
//  TransferManager.swift
//  Music Transfer
//
//  Created by panandafog on 05.09.2021.
//

import Combine
import RealmSwift
import SwiftUI

class TransferManager: ManagingDatabase, ObservableObject {
    
    typealias SpotifyAddTracksOperationHandler = (SpotifyAddTracksOperation) -> Void
    typealias LastFmAddTracksOperationHandler = (LastFmAddTracksOperation) -> Void
    typealias VKAddTracksOperationHandler = (VKAddTracksOperation) -> Void
    
    // MARK: - Singleton
    
    static var shared = TransferManager()
    
    // MARK: - Constants
    
    var services: [APIService] = [SpotifyService(), LastFmService()]
    let objectWillChange = ObservableObjectPublisher()
    
    // MARK: - Services choosing
    
    @Published var selectionFrom = 0 {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    @Published var selectionTo = 1 {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Operation state
    
    @Published var operationInProgress = false {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Captcha
    
    @Published var captcha: Captcha? {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    @Published var solvingCaptcha = false {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Operation progress
    
    @Published var progressPercentage = 0.0 {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    @Published var processName = "" {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    @Published var progressActive = false {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    @Published var determinate = false {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    // Operations data
    
    @Published var operationsHistory: [TransferOperation] = [] {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    private var spotifyAddOperations: Results<SpotifyAddTracksOperationRealm>?
    private var vkAddOperations: Results<VKAddTracksOperationRealm>?
    private var lastFmAddOperations: Results<LastFmAddTracksOperationRealm>?
    
    private var spotifyAddOperationsHistoryToken: NotificationToken?
    private var vkAddOperationsHistoryToken: NotificationToken?
    private var lastFmAddOperationsHistoryToken: NotificationToken?
    
    private init() {
        spotifyAddOperations = databaseManager.read()
        vkAddOperations = databaseManager.read()
        lastFmAddOperations = databaseManager.read()
        
        spotifyAddOperationsHistoryToken = spotifyAddOperations?.observe { [self] _ in
            updateOperationsHistory()
        }
        vkAddOperationsHistoryToken = vkAddOperations?.observe { [self] _ in
            updateOperationsHistory()
        }
        lastFmAddOperationsHistoryToken = lastFmAddOperations?.observe { [self] _ in
            updateOperationsHistory()
        }
    }
    
    func off() {
        self.progressPercentage = 0.0
        self.processName = ""
        self.progressActive = false
        self.operationInProgress = false
        self.determinate = false
    }
    
    // MARK: - Perform operations
    
    func ableToTransfer(from departureService: APIService, to destinationService: APIService) -> Bool {
        guard !operationInProgress else {
            return false
        }
        
        guard type(of: departureService) != type(of: destinationService) else {
            return false
        }
        
        for service in [departureService, destinationService] {
            guard service.isAuthorised else {
                return false
            }
            guard service.gotTracks else {
                return false
            }
        }
        
        return true
    }
    
    func transfer(from departureService: APIService, to destinationService: APIService) {
        guard ableToTransfer(from: departureService, to: destinationService) else {
            return
        }
        
        if let spotifyService = destinationService as? SpotifyService {
            let operation = SpotifyAddTracksOperation(tracksToAdd: departureService.savedTracks)
            let operationUpdateHandler: SpotifyAddTracksOperationHandler = { [self] operation in
                save(operation)
            }
            spotifyService.addTracks(
                operation: operation,
                updateHandler: operationUpdateHandler
            )
        }
        
        if let vkService = destinationService as? VKService {
            var tracksToAdd = vkService.filterTracksToAdd(departureService.savedTracks)
            let operation = VKAddTracksOperation(tracksToAdd: tracksToAdd)
            let operationUpdateHandler: VKAddTracksOperationHandler = { [self] operation in
                save(operation)
            }
            
            vkService.addTracks(
                operation: operation,
                updateHandler: operationUpdateHandler
            )
        }
        
        if let lastFmService = destinationService as? LastFmService {
            let operation = LastFmAddTracksOperation(tracksToAdd: departureService.savedTracks)
            let operationUpdateHandler: LastFmAddTracksOperationHandler = { [self] operation in
                save(operation)
                
            }
            lastFmService.addTracks(
                operation: operation,
                updateHandler: operationUpdateHandler
            )
        }
    }
    
    private func updateOperationsHistory() {
        var newHistory = [TransferOperation]()
        newHistory.append(
            contentsOf: spotifyAddOperations?.map {
                $0.spotifyAddTracksOperation
            } ?? []
        )
        newHistory.append(
            contentsOf: vkAddOperations?.map {
                $0.vkAddTracksOperation
            } ?? []
        )
        newHistory.append(
            contentsOf: lastFmAddOperations?.map {
                $0.lastFmAddTracksOperation
            } ?? []
        )
        operationsHistory = newHistory.sorted { lhs, rhs in
            lhs.started ?? Date.distantPast
                > rhs.started ?? Date.distantPast
        }
    }
}
