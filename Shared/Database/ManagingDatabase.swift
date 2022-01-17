//
//  ManagingDatabase.swift.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 07.11.2021.
//

protocol ManagingDatabase {
    
    func save(_ operation: SpotifyAddTracksOperation)
    func save(_ operation: VKAddTracksOperation)
    func save(_ suboperation: VKSearchTracksSuboperation)
    func save(_ suboperation: VKLikeTracksSuboperation)
    func save(_ suboperation: SpotifySearchTracksSuboperation)
    func save(_ suboperation: SpotifyLikeTracksSuboperation)
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
