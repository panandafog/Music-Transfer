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
    
    private var configuration: Realm.Configuration
    
    var realm: Realm {
        do {
            return try Realm(configuration: configuration)
        } catch {
            guard let realmURL = configuration.fileURL else {
                fatalError("Could not locate realm database to delete")
            }
            let realmURLs = [
                realmURL,
                realmURL.appendingPathExtension("lock"),
                realmURL.appendingPathExtension("note"),
                realmURL.appendingPathExtension("management")
            ]
            
            for URL in realmURLs {
                do {
                    try FileManager.default.removeItem(at: URL)
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
            
            do {
                return try Realm(configuration: configuration)
            } catch {
                fatalError("Realm can't be created")
            }
        }
    }
    
    init(configuration: Realm.Configuration) {
        self.configuration = configuration
        
        Logger.write(
            to: .database,
            "Initialized database manager",
            "Configruration: \(String(describing: configuration))",
            "Realm file location: \(realm.configuration.fileURL?.path ?? "null")"
        )
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
