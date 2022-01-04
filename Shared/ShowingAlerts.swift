//
//  ShowingAlerts.swift
//  Music Transfer
//
//  Created by panandafog on 04.01.2022.
//

import Foundation

protocol ShowingAlerts {
    
    func handleError(_ error: Error)
}

extension ShowingAlerts {
    
    private var alertsManager: AlertsManager {
        AlertsManager.shared
    }
    
    func handleError(_ error: Error) {
        alertsManager.showErrorAlert(error)
    }
}
