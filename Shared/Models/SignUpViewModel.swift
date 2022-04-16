//
//  SignUpViewModel.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Combine
import Foundation

class SignUpViewModel: ObservableObject {
    
    typealias CredentialsHandler = (_: String, _: String, _: String) -> Void
    
    var service: APIService
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    var shouldDismissView = false {
        didSet {
            DispatchQueue.main.async {
                self.viewDismissalModePublisher.send(self.shouldDismissView)
            }
            service.showingSignUp = !shouldDismissView
        }
    }
    
    @Published var login = ""
    @Published var email = ""
    @Published var password = ""
    @Published var passwordConfirmation = ""
    @Published var completion: CredentialsHandler
    
    @Published var error: Error? {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    var credentialsAreValid: Bool {
        !login.isEmpty
        && !email.isEmpty
        && !password.isEmpty
        && password == passwordConfirmation
    }
    
    init(
        service: APIService,
        login: String? = nil,
        password: String? = nil,
        email: String? = nil,
        completion: @escaping CredentialsHandler
    ) {
        self.service = service
        self.login = login ?? ""
        self.password = password ?? ""
        self.passwordConfirmation = password ?? ""
        self.email = email ?? ""
        self.completion = completion
    }
    
    func complete() {
        guard credentialsAreValid else {
            return
        }
        
        completion(login, email, password)
    }
}
