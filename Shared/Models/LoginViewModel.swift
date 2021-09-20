//
//  LoginViewModel.swift
//  Music Transfer
//
//  Created by panandafog on 25.01.2021.
//

import Foundation
import Combine

class LoginViewModel: ObservableObject {
    
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }
    
    @Published var login = ""
    @Published var password = ""
    @Published var code = ""
    @Published var twoFactor: Bool
    @Published var captcha: Captcha.Solved?
    @Published var completion: ((_: String, _: String, _: String?, _: Captcha.Solved?) -> Void)
    
    init(login: String? = nil,
         password: String? = nil,
         code: String? = nil,
         twoFactor: Bool,
         captcha: Captcha.Solved?,
         completion: @escaping ((_: String, _: String, _: String?, _: Captcha.Solved?) -> Void)) {
        self.login = login ?? ""
        self.password = password ?? ""
        self.code = code ?? ""
        self.twoFactor = twoFactor
        self.captcha = captcha
        self.completion = completion
    }
}
