//
//  CacheManager.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 10.10.2021.
//

import RealmSwift

protocol CacheManager {
    
    func write(_ objects: [Object])
    func read<ObjectType: Object>() -> Results<ObjectType>
    func deleteAll<ObjectType: Object>(_ objectType: ObjectType.Type)
    func count<ObjectType: Object>(_ objectType: ObjectType.Type) -> Int
}

// MARK: - DatabaseManagerImpl

class CacheManagerImpl: CacheManager {
    
    private let configuration: Realm.Configuration
    
    private var realm: Realm {
        do {
            return try Realm(configuration: configuration)
        } catch {
            Logger.write(to: .database, type: .fault, "Realm can't be created!")
            fatalError("Realm can't be created!")
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
