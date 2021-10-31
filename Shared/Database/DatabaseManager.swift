//
//  DatabaseManager.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import RealmSwift

protocol DatabaseManager {
    
    func write(_ objects: [Object])
    func read<ObjectType: Object>() -> Results<ObjectType>
    func deleteAll<ObjectType: Object>(_ objectType: ObjectType.Type)
    func count<ObjectType: Object>(_ objectType: ObjectType.Type) -> Int
}

// MARK: - DatabaseManagerImpl

class DatabaseManagerImpl: DatabaseManager {
    
    private let configuration: Realm.Configuration
    
    var realm: Realm {
        do {
            return try Realm(configuration: configuration)
        } catch {
            fatalError("Realm can't be created")
        }
    }
    
    init(configuration: Realm.Configuration) {
        self.configuration = configuration
    }
    
    // MARK: - Managing data methods
    
    func write(_ objects: [Object]) {
        try? realm.write {
            realm.add(objects, update: .modified)
        }
    }
    
    func read<ObjectType>() -> Results<ObjectType> where ObjectType: Object {
        realm.objects(ObjectType.self)
    }
    
    func deleteAll<ObjectType>(_ objectType: ObjectType.Type) where ObjectType: Object {
        try? realm.write {
            realm.delete(realm.objects(ObjectType.self))
        }
    }
    
    func count<ObjectType>(_ objectType: ObjectType.Type) -> Int where ObjectType: Object {
        realm.objects(ObjectType.self).count
    }
}
