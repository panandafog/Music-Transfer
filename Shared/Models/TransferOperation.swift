//
//  TransferOperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 06.11.2021.
//

import Foundation

protocol TransferOperation {
    var id: String { get }
    var suboperations: [TransferSuboperation] { get }
    
    var started: Date? { get }
    var completed: Date? { get }
    
    var tracksCount: Int? { get }
}

extension TransferOperation {
    
    var started: Date? {
        dates(.started).min()
    }
    
    var completed: Date? {
        dates(.completed).max()
    }
    
    var tracksToTransfer: [SharedTrack]? {
        if let suboperation: SpotifySearchTracksSuboperation = getSuboperation() {
            return suboperation.tracks.map { $0.trackToSearch }
        }
        if let suboperation: VKSearchTracksSuboperation = getSuboperation() {
            return suboperation.tracks.map { $0.trackToSearch }
        }
        if let suboperation: LastFmSearchTracksSuboperation = getSuboperation() {
            return suboperation.tracks.map { $0.trackToSearch }
        }
        return nil
    }
    
    var transferredTracks: [SharedTrack]? {
        if let suboperation: SpotifyLikeTracksSuboperation = getSuboperation() {
            let packages = suboperation.trackPackagesToLike
            var tracks = [SharedTrack]()
            
            packages.forEach { package in
                if package.liked {
                    tracks.append(contentsOf: package.tracks.map { SharedTrack(from: $0) })
                }
            }
            return tracks
        }
        if let suboperation: VKLikeTracksSuboperation = getSuboperation() {
            return suboperation.tracksToLike.map { SharedTrack(from: $0.track) }
        }
        if let suboperation: LastFmLikeTracksSuboperation = getSuboperation() {
            return suboperation.tracksToLike.map { SharedTrack(from: $0.track) }
        }
        return nil
    }
    
    var notFoundTracks: [SharedTrack]? {
        if let _: SpotifySearchTracksSuboperation = getSuboperation() {
            return []
        }
        if let suboperation: VKLikeTracksSuboperation = getSuboperation() {
            return suboperation.notFoundTracks
        }
        if let suboperation: LastFmLikeTracksSuboperation = getSuboperation() {
            return suboperation.notFoundTracks
        }
        return nil
    }
    
    var duplicates: [SharedTrack]? {
        if let suboperation: VKLikeTracksSuboperation = getSuboperation() {
            return suboperation.duplicates
        }
        return nil
    }
    
    func getTracks(_ category: TracksInfoCategory) -> [SharedTrack] {
        switch category {
        case .tracksToTransfer:
            return tracksToTransfer ?? []
        case .transferredTracks:
            return transferredTracks ?? []
        case .notFoundTracks:
            return notFoundTracks ?? []
        case .duplicates:
            return duplicates ?? []
        }
    }
    
    private func getSuboperation<T: TransferSuboperation>() -> T? {
        for suboperation in suboperations {
            if let castedSuboperation = suboperation as? T {
                return castedSuboperation
            }
        }
        return nil
    }
    
    private func dates(_ type: DateType) -> [Date] {
        var dates: [Date] = []
        
        for suboperation in suboperations {
            var date: Date?
            
            switch type {
            case .started:
                date = suboperation.started
            case .completed:
                date = suboperation.completed
            }
            
            if let date = date {
                dates.append(date)
            }
        }
        
        return dates
    }
}

enum DateType {
    case started
    case completed
}

enum TracksInfoCategory: Int, CaseIterable {
    case tracksToTransfer
    case transferredTracks
    case notFoundTracks
    case duplicates
    
    var displayableName: String {
        switch self {
        case .tracksToTransfer:
            return "Tracks to transfer"
        case .transferredTracks:
            return "Transferred tracks"
        case .notFoundTracks:
            return "Not found tracks"
        case .duplicates:
            return "Duplicates"
        }
    }
}
