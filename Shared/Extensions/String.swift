//
//  String.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 10.10.2021.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func truncating(length: Int, trailing: String = "…") -> String {
        (self.count > length) ? self.prefix(length) + trailing : self
    }
    
    mutating func truncate(length: Int, trailing: String = "…") {
        self = self.truncating(length: length, trailing: trailing)
    }
}
