//
//  TransferOperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 06.11.2021.
//

protocol TransferOperation {
    var id: String { get }
    var suboperations: [TransferSuboperation] { get }
    var started: Bool { get }
    var completed: Bool { get }
}

extension TransferOperation {
    var started: Bool {
        for suboperation in suboperations {
            if suboperation.started {
                return true
            }
        }
        return false
    }
    
    var completed: Bool {
        for suboperation in suboperations {
            if !suboperation.completed {
                return false
            }
        }
        return true
    }
}
