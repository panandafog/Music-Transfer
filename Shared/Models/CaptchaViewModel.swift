//
//  CaptchaViewModel.swift
//  Music Transfer
//
//  Created by panandafog on 23.03.2021.
//

import Foundation
import Combine

class CaptchaViewModel: ObservableObject {
    
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }
    
    @Published var solution = ""
    @Published var url: URL
    @Published var errorInfo: VKCaptcha.ErrorMessage
    @Published var completion: Captcha.CaptchaSolveCompletion
    
    init(solution: String? = nil,
         errorInfo: VKCaptcha.ErrorMessage,
         url: URL,
         completion: @escaping Captcha.CaptchaSolveCompletion) {
        if let solution = solution {
            self.solution = solution
        }
        self.url = url
        self.errorInfo = errorInfo
        self.completion = completion
    }
}
