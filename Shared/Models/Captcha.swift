//
//  Captcha.swift
//  Music Transfer
//
//  Created by panandafog on 05.09.2021.
//

import Foundation

struct Captcha {
    
    typealias CaptchaSolveCompletion = (_: Solved) -> Void
    
    let errorMessage: VKCaptcha.ErrorMessage
    let solveCompletion: Captcha.CaptchaSolveCompletion
    
    var url: URL? {
        URL(string: errorMessage.error.captcha_img)
    }
    
    init(errorMessage: VKCaptcha.ErrorMessage, solveCompletion: @escaping Captcha.CaptchaSolveCompletion) {
        self.errorMessage = errorMessage
        self.solveCompletion = solveCompletion
    }
}

// MARK: - Extensions

extension Captcha {
    
    struct Solved {
        let sid: String
        let key: String
    }
}
