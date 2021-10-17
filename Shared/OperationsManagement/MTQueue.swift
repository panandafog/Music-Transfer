//
//  MTQueue.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 10.10.2021.
//

import Foundation

class MTQueue<OperationType: MTOperation> {
    
    typealias Completion = () -> Void
    typealias ProgressHandler = (Double) -> Void
    
    // MARK: - Constants
    
    private let group = DispatchGroup()
    private let concurrentQueue = DispatchQueue(label: "MTConcurrentQueue", attributes: [.concurrent])
    
    // MARK: - Instance properties
    
    private (set) var pendingOperations: [OperationType]
    private var completedOperations = [OperationType]() {
        didSet {
            handleNewProgress()
        }
    }
    private var failedOperations = [OperationType]()
    
    private let mode: Mode
    
    private let completion: Completion
    private let progressHandler: ProgressHandler?
    
    private (set) var completed = false
    
    private var progressPercentage: Double {
        Double(completedOperations.count) / Double(completedOperations.count + pendingOperations.count) * 100
    }
    
    // MARK: - Initializers
    
    init(operations: [OperationType], mode: Mode, completion: @escaping Completion, progressHandler: ProgressHandler?) {
        self.pendingOperations = operations
        self.mode = mode
        self.completion = completion
        self.progressHandler = progressHandler
    }
    
    func run() {
        switch mode {
        case .concurrent:
            pendingOperations.forEach { operation in
                concurrentExecOperation(operation)
            }
            group.notify(queue: concurrentQueue) { [self] in
                completed = true
                completion()
            }
        case .serial:
            var rec: (() -> Void)? = nil
            rec = { [self] in
                guard let operation = pendingOperations.first else {
                    completed = true
                    completion()
                    return
                }
                operation.execute { [self] in
                    pendingOperations.removeAll {
                        $0 == operation
                    }
                    completedOperations.append(operation)
                    rec!()
                }
            }
            rec!()
        }
    }
    
    func addOperation(operation: OperationType) throws {
        if completed {
            throw AddingError.queueAlreadyCompleted
        }
        
        switch mode {
        case .concurrent:
            concurrentExecOperation(operation)
        case .serial:
            pendingOperations.append(operation)
        }
    }
    
    private func concurrentExecOperation(_ operation: OperationType) {
        group.enter()
        concurrentQueue.async { [self] in
            operation.execute(executeCompletion: nil)
            pendingOperations.removeAll {
                $0 == operation
            }
            completedOperations.append(operation)
            group.leave()
        }
    }
    
    private func handleNewProgress() {
        progressHandler?(progressPercentage)
    }
}

extension MTQueue {
    
    enum Mode {
        case concurrent
        case serial
    }
    
    enum AddingError: Error {
        case queueAlreadyCompleted
    }
}
