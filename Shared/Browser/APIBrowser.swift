//
//  APIBrowser.swift
//  Music Transfer
//
//  Created by panandafog on 09.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

#if os(macOS)
import Cocoa
protocol APIBrowser: NSViewRepresentable {
    var url: URL? { get }
    func load()
}
#else
import Combine
protocol APIBrowser: UIViewRepresentable, ObservableObject {
    var url: URL? { get }
    var viewDismissalModePublisher: PassthroughSubject<Bool, Never> { get }
    func load()
}
#endif
