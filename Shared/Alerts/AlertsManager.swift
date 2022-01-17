//
//  AlertsManager.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 29.12.2021.
//

import SwiftUI

class AlertsManager: ObservableObject {
    
    static var shared = AlertsManager()
    
    @Published var alert: Alert? {
        willSet {
            DispatchQueue.main.async {
                AlertsManager.shared.objectWillChange.send()
            }
        }
    }
    
    private init() { }
    
    func showErrorAlert(_ error: Error) {
        var text = error.localizedDescription
        
        if let displayable = error as? DisplayableError {
            text = displayable.message
        }
        
        DispatchQueue.main.async {
            self.alert = Alert(title: Text(text), dismissButton: .default(Text("Dismiss")))
        }
    }
}
