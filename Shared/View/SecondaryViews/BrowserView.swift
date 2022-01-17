//
//  BrowserView.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct BrowserView<Browser: APIBrowser>: View {
    
    private let width: CGFloat = 500
    private let height: CGFloat = 700
    
    @ObservedObject var browser: Browser
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack {
            self.browser
                .onAppear {
                    self.browser.load()
                }
                .onReceive(browser.viewDismissalModePublisher) { shouldDismiss in
                    if shouldDismiss {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .modify {
#if os(macOS)
            $0
                .frame(minWidth: width, minHeight: height)
                .padding(10)
#else
            $0
                .ignoresSafeArea()
#endif
        }
    }
}
