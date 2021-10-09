//
//  TransferState.swift
//  Music Transfer
//
//  Created by panandafog on 05.09.2021.
//

import Combine
import SwiftUI

class TransferState: ObservableObject {
    
    // MARK: - Singleton
    
    static var shared = TransferState()
    private init() { }
    
    // MARK: - Constants
    
    private(set) var services: [APIService] = [SpotifyService.shared, VKService.shared]
    let objectWillChange = ObservableObjectPublisher()
    
    // MARK: - Operations management
    
    @Published var operationInProgress = false {
        willSet {
            DispatchQueue.main.async {
                TransferState.shared.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Captcha
    
    @Published var captcha: Captcha? {
        willSet {
            DispatchQueue.main.async {
                TransferState.shared.objectWillChange.send()
            }
        }
    }
    
    @Published var solvingCaptcha = false {
        willSet {
            DispatchQueue.main.async {
                TransferState.shared.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Operation progress
    
    @Published var progressPercentage = 0.0 {
        willSet {
            DispatchQueue.main.async {
                TransferState.shared.objectWillChange.send()
            }
        }
    }
    @Published var processName = "" {
        willSet {
            DispatchQueue.main.async {
                TransferState.shared.objectWillChange.send()
            }
        }
    }
    @Published var active = false {
        willSet {
            DispatchQueue.main.async {
                TransferState.shared.objectWillChange.send()
            }
        }
    }
    @Published var determinate = false {
        willSet {
            DispatchQueue.main.async {
                TransferState.shared.objectWillChange.send()
            }
        }
    }
    
    func off() {
        self.progressPercentage = 0.0
        self.processName = ""
        self.active = false
        self.determinate = false
    }
}
