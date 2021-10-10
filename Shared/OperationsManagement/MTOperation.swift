//
//  MTOperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 10.10.2021.
//

import Foundation

protocol MTOperation: Equatable {
    
    typealias QueueCompletion = () -> Void

    var completed: Bool { get }
    
    func execute(executeCompletion: QueueCompletion?)
}
