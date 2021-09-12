//
//  BrowserViewDelegate.swift
//  Music Transfer
//
//  Created by panandafog on 02.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//


import SwiftUI

class BrowserViewDelegate {

    private static var keyWindow: NSWindow?

    static var shared: BrowserViewDelegate = {
        let instance = BrowserViewDelegate()
        return instance
    }()

    private init() {}

    func openBrowser<Browser: APIBrowser>(browser: Browser) {

        let browserView = BrowserView<Browser>(browser: browser)

        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 810, height: 850),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.title = "Log in"
        window.setFrameAutosaveName("Log in Window")
        window.contentView = NSHostingView(rootView: browserView)
        window.makeKeyAndOrderFront(nil)

        window.isReleasedWhenClosed = false

        BrowserViewDelegate.keyWindow = window
    }

    func closeBrowser() {
        BrowserViewDelegate.keyWindow?.close()
        BrowserViewDelegate.keyWindow = nil
    }
}
