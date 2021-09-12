//
//  TracksTableViewDelegate.swift
//  Music Transfer
//
//  Created by panandafog on 28.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

class TracksTableViewDelegate {
    
    private static var keyWindow: NSWindow?
    
    static var shared: TracksTableViewDelegate = {
        let instance = TracksTableViewDelegate()
        return instance
    }()
    
    private init() {}
    
    func open(tracks: [SharedTrack], name: String) {
        DispatchQueue.main.async {
            
            let tableView = TracksTable(tracks: .init(
                                            get: { tracks },
                                            set: { _ in }),
                                        name: name)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 810, height: 850),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            window.center()
            window.title = name
            window.setFrameAutosaveName(name + " Window")
            window.contentView = NSHostingView(rootView: tableView)
            window.makeKeyAndOrderFront(nil)
            
            window.isReleasedWhenClosed = false
            
            TracksTableViewDelegate.keyWindow = window
        }
    }
    
    func close() {
        DispatchQueue.main.async {
            TracksTableViewDelegate.keyWindow?.close()
            TracksTableViewDelegate.keyWindow = nil
        }
    }
}
