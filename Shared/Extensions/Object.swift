//
//  Object.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

extension Object {
    
    static func incrementedPK(primaryKey: String = "id") -> Int {
        let realm = try! Realm()
        
        return realm
            .objects(Self.self)
            .max(ofProperty: primaryKey)
        as Int? ?? 0 + 1
    }
}
