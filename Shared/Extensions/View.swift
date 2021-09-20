//
//  View.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 13.09.2021.
//

import SwiftUI

extension View {
    
    @inlinable
    func modify<T: View>(@ViewBuilder modifier: (Self) -> T) -> T {
        modifier(self)
    }
}
