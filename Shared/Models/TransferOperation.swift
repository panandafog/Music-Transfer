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
