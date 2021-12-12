//
//  LoginViewModel.swift
//  Music Transfer
//
//  Created by panandafog on 25.01.2021.
//

import Combine
import Foundation

class LoginViewModel: ObservableObject {
    
    var service: APIService
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    var shouldDismissView = false {
        didSet {
            DispatchQueue.main.async {
                self.viewDismissalModePublisher.send(self.shouldDismissView)
            }
            service.showingAuthorization = !shouldDismissView
        }
    }
    
    @Published var login = ""
    @Published var password = ""
    @Published var code = ""
    @Published var twoFactor: Bool
    @Published var captcha: Captcha.Solved?
    @Published var completion: ((_: String, _: String, _: String?, _: Captcha.Solved?) -> Void)
    
    init(
        service: APIService,
        twoFactor: Bool,
        captcha: Captcha.Solved?,
        login: String? = nil,
        password: String? = nil,
        code: String? = nil,
        completion: @escaping ((_: String, _: String, _: String?, _: Captcha.Solved?) -> Void)
    ) {
        self.service = service
        self.login = login ?? ""
        self.password = password ?? ""
        self.code = code ?? ""
        self.twoFactor = twoFactor
        self.captcha = captcha
        self.completion = completion
    }
}
