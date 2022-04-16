//
//  EmailConfirmationViewModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Combine
import Foundation

class EmailConfirmationViewModel: ObservableObject {
    
    typealias TokenHandler = (_: String) -> Void
    
    var service: APIService
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    var shouldDismissView = false {
        didSet {
            DispatchQueue.main.async {
                self.viewDismissalModePublisher.send(self.shouldDismissView)
            }
            service.showingEmailConfirmation = !shouldDismissView
        }
    }
    
    @Published var token = ""
    @Published var completion: TokenHandler
    
    @Published var error: Error? {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    var tokenIsEntered: Bool {
        !token.isEmpty
    }
    
    init(
        service: APIService,
        token: String? = nil,
        completion: @escaping TokenHandler
    ) {
        self.service = service
        self.token = token ?? ""
        self.completion = completion
    }
    
    func complete() {
        guard tokenIsEntered else {
            return
        }
        
        completion(token)
    }
}
