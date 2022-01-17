//
//  DisplayableError.swift
//  Music Transfer
//
//  Created by panandafog on 03.01.2022.
//

protocol DisplayableError: Error {
    
    var message: String { get }
}
