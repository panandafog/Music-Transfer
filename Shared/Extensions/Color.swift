//
//  Color.swift
//  Music Transfer
//
//  Created by panandafog on 08.02.2022.
//

import SwiftUI

extension Color {
    
    static let highlightedBackground = Color("HighlightedBackgroundColor")
    
    #if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #endif
}
