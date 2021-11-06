//
//  TransferManager.swift
//  Music Transfer
//
//  Created by panandafog on 05.09.2021.
//

import Combine
import SwiftUI

class TransferManager: ObservableObject {
    
    // MARK: - Singleton
    
    static var shared = TransferManager()
    private init() { }
    
    // MARK: - Constants
    
    private(set) var services: [APIService] = [SpotifyService(), VKService()]
    let objectWillChange = ObservableObjectPublisher()
    
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
    
    @Published var active = false {
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
    
    func off() {
        self.progressPercentage = 0.0
        self.processName = ""
        self.active = false
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
            spotifyService.addTracks(departureService.savedTracks)
        }
        
        if let vkService = destinationService as? VKService {
            vkService.addTracks(departureService.savedTracks)
        }
    }
}
