//
//  List.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation
import RealmSwift

//extension Array {
//    init<ObjectType: Object>(_ objects: List<ObjectType>) {
//        var array = [ObjectType]()
//        for index in 0 ..< objects.count {
//            array.append(objects[index])
//        }
//
//        self.init(array)
//    }
//}

extension List {
    var array: [Element] {
        var tmpArray = [Element]()
        for index in 0 ..< self.count {
            tmpArray.append(self[index])
        }
        
        return tmpArray
    }
}
