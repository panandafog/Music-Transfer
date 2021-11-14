//
//  List.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

extension List {
    var array: [Element] {
        var tmpArray = [Element]()
        for index in 0 ..< self.count {
            tmpArray.append(self[index])
        }
        
        return tmpArray
    }
}
