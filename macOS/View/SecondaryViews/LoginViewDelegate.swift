//
//  LoginViewDelegate.swift
//  Music Transfer
//
//  Created by panandafog on 25.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

class LoginViewDelegate {

    private static var keyWindow: NSWindow?

    static var shared: LoginViewDelegate = {
        let instance = LoginViewDelegate()
        return instance
    }()

    private init() {}

    func open(twoFactor: Bool, captcha: Captcha.Solved?, login: String = "", password: String = "", completion: @escaping (_: String, _: String, _: String?, _: Captcha.Solved?) -> Void) {
        DispatchQueue.main.async {

            let loginView = LoginView(login: login, password: password, twoFactor: twoFactor, captcha: captcha, completion: completion)

            var window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 810, height: 850),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            window.center()
            window.title = "Log in"
            window.setFrameAutosaveName("Log in Window")
            window.contentView = NSHostingView(rootView: loginView)
            window.makeKeyAndOrderFront(nil)

            window.isReleasedWhenClosed = false

            LoginViewDelegate.keyWindow = window
        }
    }

    func close() {
        DispatchQueue.main.async {
            LoginViewDelegate.keyWindow?.close()
            LoginViewDelegate.keyWindow = nil
        }
    }
}

