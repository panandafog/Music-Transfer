//
//  BrowserView.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct BrowserView<Browser: APIBrowser>: View {

    var browser: Browser

    var body: some View {
//        GeometryReader { g in
            HStack {
                self.browser
                    .onAppear() {
                        self.browser.load()
                }
//                .frame(width: g.size.width, height: g.size.height)
            }
            .padding()
//            .frame(width: g.size.height, height: g.size.width)
//        }
    }
}
