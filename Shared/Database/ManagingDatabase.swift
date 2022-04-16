//
//  ManagingDatabase.swift.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 07.11.2021.
//

import RealmSwift

protocol ManagingDatabase {
    
    func save(_ operation: SpotifyAddTracksOperation)
    func save(_ operation: VKAddTracksOperation)
    func save(_ operation: LastFmAddTracksOperation)
    
    func readOperation(id: String) -> SpotifyAddTracksOperation?
    func readOperation(id: String) -> VKAddTracksOperation?
    func readOperation(id: String) -> LastFmAddTracksOperation?
    
    func readOperation(serverID: Int?) -> SpotifyAddTracksOperation?
    func readOperation(serverID: Int?) -> VKAddTracksOperation?
    func readOperation(serverID: Int?) -> LastFmAddTracksOperation?
    
    func save(_ suboperation: VKSearchTracksSuboperation)
    func save(_ suboperation: VKLikeTracksSuboperation)
    func save(_ suboperation: SpotifySearchTracksSuboperation)
    func save(_ suboperation: SpotifyLikeTracksSuboperation)
    func save(_ suboperation: LastFmSearchTracksSuboperation)
    func save(_ suboperation: LastFmLikeTracksSuboperation)
}

extension ManagingDatabase {
    
    var databaseManager: DatabaseManager {
        DatabaseManagerImpl(configuration: .defaultConfiguration)
    }
    
    func save(_ operation: SpotifyAddTracksOperation) {
        databaseManager.write([
            SpotifyAddTracksOperationRealm(operation)
        ])
    }
    
    func save(_ operation: VKAddTracksOperation) {
        databaseManager.write([
            VKAddTracksOperationRealm(operation)
        ])
    }
    
    func save(_ operation: LastFmAddTracksOperation) {
        databaseManager.write([
            LastFmAddTracksOperationRealm(operation)
        ])
    }
    
    func readOperation(id: String) -> SpotifyAddTracksOperation? {
        let results: Results<SpotifyAddTracksOperationRealm> = databaseManager.read()
        let operations = results.map {
            $0.spotifyAddTracksOperation
        }
        return operations.first { $0.id == id }
    }
    
    func readOperation(id: String) -> VKAddTracksOperation? {
        let results: Results<VKAddTracksOperationRealm> = databaseManager.read()
        let operations = results.map {
            $0.vkAddTracksOperation
        }
        return operations.first { $0.id == id }
    }
    
    func readOperation(id: String) -> LastFmAddTracksOperation? {
        let results: Results<LastFmAddTracksOperationRealm> = databaseManager.read()
        let operations = results.map {
            $0.lastFmAddTracksOperation
        }
        let foundOperation = operations.first { $0.id == id }
        return foundOperation
    }
    
    func readOperation(serverID: Int?) -> SpotifyAddTracksOperation? {
        guard serverID != nil else { return nil }
        
        let results: Results<SpotifyAddTracksOperationRealm> = databaseManager.read()
        let operations = results.map {
            $0.spotifyAddTracksOperation
        }
        return operations.first { $0.serverID == serverID }
    }
    
    func readOperation(serverID: Int?) -> VKAddTracksOperation? {
        guard serverID != nil else { return nil }
        
        let results: Results<VKAddTracksOperationRealm> = databaseManager.read()
        let operations = results.map {
            $0.vkAddTracksOperation
        }
        return operations.first { $0.serverID == serverID }
    }
    
    func readOperation(serverID: Int?) -> LastFmAddTracksOperation? {
        guard serverID != nil else { return nil }
        
        let results: Results<LastFmAddTracksOperationRealm> = databaseManager.read()
        let operations = results.map {
            $0.lastFmAddTracksOperation
        }
        return operations.first { $0.serverID == serverID }
    }
    
    func save(_ suboperation: VKSearchTracksSuboperation) {
        databaseManager.write([
            VKSearchTracksSuboperationRealm(suboperation)
        ])
    }
    
    func save(_ suboperation: VKLikeTracksSuboperation) {
        databaseManager.write([
            VKLikeTracksSuboperationRealm(suboperation)
        ])
    }
    
    func save(_ suboperation: SpotifySearchTracksSuboperation) {
        databaseManager.write([
            SpotifySearchTracksSuboperationRealm(suboperation)
        ])
    }
    
    func save(_ suboperation: SpotifyLikeTracksSuboperation) {
        databaseManager.write([
            SpotifyLikeTracksSuboperationRealm(suboperation)
        ])
    }
    
    func save(_ suboperation: LastFmSearchTracksSuboperation) {
        databaseManager.write([
            LastFmSearchTracksSuboperationRealm(suboperation)
        ])
    }
    
    func save(_ suboperation: LastFmLikeTracksSuboperation) {
        databaseManager.write([
            LastFmLikeTracksSuboperationRealm(suboperation)
        ])
    }
}
