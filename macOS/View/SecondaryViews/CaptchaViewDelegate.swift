//
//  CaptchaViewDelegate.swift
//  Music Transfer
//
//  Created by panandafog on 21.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

class CaptchaViewDelegate {

    private static var keyWindow: NSWindow?

    static var shared: CaptchaViewDelegate = {
        let instance = CaptchaViewDelegate()
        return instance
    }()

    private init() {}

    func open(errorMsg: VKCaptcha.ErrorMessage, completion: @escaping (_: Captcha.Solved) -> Void) {
        DispatchQueue.main.async {
            
            let captchaView = CaptchaView(
                captcha: .init(
                    errorMessage: errorMsg,
                    solveCompletion: completion
                )
            )

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 810, height: 850),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            window.center()
            window.title = "Captcha"
            window.setFrameAutosaveName("Captcha Window")
            window.contentView = NSHostingView(rootView: captchaView)
            window.makeKeyAndOrderFront(nil)

            window.isReleasedWhenClosed = false

            CaptchaViewDelegate.keyWindow = window
            
            NSApp.requestUserAttention(.criticalRequest)
        }
    }

    func close() {
        DispatchQueue.main.async {
            CaptchaViewDelegate.keyWindow?.close()
            CaptchaViewDelegate.keyWindow = nil
        }
    }
}
