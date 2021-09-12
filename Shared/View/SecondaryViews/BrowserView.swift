//
//  BrowserView.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct BrowserView<Browser: APIBrowser>: View {
    
    #if os(macOS)
    var browser: Browser
    #else
    @ObservedObject var browser: Browser
    @Environment(\.presentationMode) private var presentationMode
    #endif
    
    var body: some View {
        HStack {
            #if os(macOS)
            self.browser
                .onAppear() {
                    self.browser.load()
                }
            #else
            self.browser
                .onAppear() {
                    self.browser.load()
                }
                .onReceive(browser.viewDismissalModePublisher) { shouldDismiss in
                    if shouldDismiss {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            #endif
        }
        .padding()
    }
}
