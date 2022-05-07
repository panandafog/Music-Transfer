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
    
    var services: [APIService] = [SpotifyService(), VKService(), LastFmService(), MTService()]
    var mtService = MTService()
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
    
    @Published var uploadingHistoryInProgress = false {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    @Published var updatingHistoryInProgress = false {
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
    
    @Published var savedOperationsHistory: [TransferOperation] = [] {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    @Published var loadingRemoteOperationsHistory: Bool = false {
        willSet {
            DispatchQueue.main.async {
                TransferManager.shared.objectWillChange.send()
            }
        }
    }
    
    @Published var remoteOperationsHistory: [MTHistoryEntry] = [] {
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
            updateSavedOperationsHistory()
        }
        vkAddOperationsHistoryToken = vkAddOperations?.observe { [self] _ in
            updateSavedOperationsHistory()
        }
        lastFmAddOperationsHistoryToken = lastFmAddOperations?.observe { [self] _ in
            updateSavedOperationsHistory()
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
            let tracksToAdd = vkService.filterTracksToAdd(departureService.savedTracks)
            let operation = VKAddTracksOperation(tracksToAdd: tracksToAdd)
            let operationUpdateHandler: VKAddTracksOperationHandler = { [self] updatedOperation in
                let updatedOperation = updatedOperation

                let savedOperation: VKAddTracksOperation? = readOperation(id: updatedOperation.id)
                let serverID = savedOperation?.serverID
//                let serverID = getSaved(operation: updatedOperation)?.serverID
                if let serverID = serverID {
                    updatedOperation.serverID = serverID
                }
                save(updatedOperation)
                mtService.saveOperation(
                    VKAddTracksOperationServerModel.init(clientModel: updatedOperation),
                    completion: { result in
                        switch result {
                        case .success(let serverModel):
//                            if serverID == nil {
//                                let savedModel = self.readOperation(serverID: serverModel.clientModel.serverID) ?? serverModel.clientModel
//                                savedModel.serverID = serverModel.id
//                                self.save(savedModel)
//                            }
                            let clientModel = serverModel.clientModel
                            clientModel.id = updatedOperation.id
                            self.save(clientModel)
                        default:
                            break
                        }
                })
            }
            
            vkService.addTracks(
                operation: operation,
                updateHandler: operationUpdateHandler
            )
        }
        
        if let lastFmService = destinationService as? LastFmService {
            let operation = LastFmAddTracksOperation(tracksToAdd: departureService.savedTracks)
            let operationUpdateHandler: LastFmAddTracksOperationHandler = { [self] updatedOperation in
                let updatedOperation = updatedOperation
                let savedOperation: LastFmAddTracksOperation? = readOperation(id: updatedOperation.id)
                let serverID = savedOperation?.serverID
//                let serverID = getSaved(operation: updatedOperation)?.serverID
                if let serverID = serverID {
                    updatedOperation.serverID = serverID
                }
                save(updatedOperation)
                mtService.saveOperation(
                    LastFmAddTracksOperationServerModel.init(clientModel: updatedOperation),
                    completion: { result in
                        switch result {
                        case .success(let serverModel):
//                            if serverID == nil {
//                                let savedModel = self.readOperation(serverID: serverModel.clientModel.serverID) ?? serverModel.clientModel
//                                savedModel.serverID = serverModel.id
//                                savedModel.id = updatedOperation.id
//                                self.save(savedModel)
//                            }
                            let clientModel = serverModel.clientModel
                            clientModel.id = updatedOperation.id
                            self.save(clientModel)
                        default:
                            break
                        }
                })
            }
            lastFmService.addTracks(
                operation: operation,
                updateHandler: operationUpdateHandler
            )
        }
    }
    
    private func updateSavedOperationsHistory() {
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
        savedOperationsHistory = newHistory.sorted { lhs, rhs in
            lhs.started ?? Date.distantPast
                > rhs.started ?? Date.distantPast
        }
    }
    
    func updateRemoteOperationsHistory(errorHandler: ((Error) -> Void)? = nil) {
        updatingHistoryInProgress = true
        remoteOperationsHistory = []
        
        mtService.getHistory { [ weak self ] result in
            self?.updatingHistoryInProgress = false
            switch result {
            case .success(let newEntries):
                self?.remoteOperationsHistory = newEntries
            case .failure(let error):
                errorHandler?(error)
            }
        }
    }
}
