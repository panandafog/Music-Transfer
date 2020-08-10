//
//  APIBrowser.swift
//  Music Transfer
//
//  Created by panandafog on 09.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

protocol APIBrowser: NSViewRepresentable {
    var url: URL? { get }
    func load()
}
