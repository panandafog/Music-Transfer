//
//  MTHistoryEntryPreview.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 16.04.2022.
//

import Foundation

enum MTHistoryEntryPreview {
    
    case entry(MTHistoryEntry)
    case operation(TransferOperation)
    
    var started: Date? {
        switch self {
        case .entry(let mtHistoryEntry):
            if let startedStr = mtHistoryEntry.started {
                return DateFormatter.mt.date(from: startedStr)
            } else {
                return nil
            }
        case .operation(let transferOperation):
            return transferOperation.started
        }
    }
    
    var completed: Date? {
        switch self {
        case .entry(let mtHistoryEntry):
            if let completedStr = mtHistoryEntry.completed {
                return DateFormatter.mt.date(from: completedStr)
            } else {
                return nil
            }
        case .operation(let transferOperation):
            return transferOperation.completed
        }
    }
}
