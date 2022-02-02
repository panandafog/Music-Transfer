//
//  KeyEventHandling.swift
//  Music Transfer
//
//  Created by panandafog on 18.01.2022.
//

import SwiftUI

struct KeyEventHandling: NSViewRepresentable {
    
    typealias EventHandler = (NSEvent) -> Void
    
    let eventHandler: EventHandler
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.eventHandler = eventHandler
        DispatchQueue.main.async { // wait till next event cycle
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}

extension KeyEventHandling {
    
    class KeyView: NSView {
        
        var eventHandler: EventHandler?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            eventHandler?(event)
        }
    }
}
