//
//  MD5.swift
//  Music Transfer
//
//  Created by panandafog on 12.12.2021.
//

import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

enum MD5 {
    
    static func makeMD5(from string: String, kind: Kind) -> String {
        let md5Data = makeMD5(from: string)
        
        switch kind {
        case .hex:
            return md5Data.map { String(format: "%02hhx", $0) }.joined()
        case .base64:
            return md5Data.base64EncodedString()
        }
    }
    
    static func makeMD5(from string: String) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: length)
        
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }
    
}

extension MD5 {
    
    enum Kind {
        case hex
        case base64
    }
}
