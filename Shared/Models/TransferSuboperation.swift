//
//  TransferSuboperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 17.10.2021.
//

import Foundation

protocol TransferSuboperation {
    var started: Date? { get }
    var completed: Date? { get }
}
