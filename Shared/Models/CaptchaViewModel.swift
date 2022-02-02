//
//  CaptchaViewModel.swift
//  Music Transfer
//
//  Created by panandafog on 23.03.2021.
//

import Combine
import Foundation

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
    
    init(
        errorInfo: VKCaptcha.ErrorMessage,
        url: URL,
        solution: String? = nil,
        completion: @escaping Captcha.CaptchaSolveCompletion
    ) {
        if let solution = solution {
            self.solution = solution
        }
        self.url = url
        self.errorInfo = errorInfo
        self.completion = completion
    }
}
