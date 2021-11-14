//
//  Logger.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 10.10.2021.
//

// swiftlint:disable function_default_parameter_at_end

import OSLog

enum Logger {
    
    private static let messageSeparator = "\n\n"
    private static let messageLengthLimit = 2_048
    private static let messageTrailing = "..."
    
    static func write(to log: Log, type: LogType = .default, _ messages: String...) {
        write(to: log, type: type, messages)
    }
    
    static func write(_ error: RequestError) {
        writeErrorMessage(
            log: .network,
            "Request failed.",
            "Error: \(String(describing: error.message))",
            "Description: \(error.localizedDescription)"
        )
    }
    
    private static func writeErrorMessage(log: Log, _ messages: String...) {
        write(to: log, type: .error, messages)
    }
    
    private static func write(to log: Log, type: LogType = .default, _ messages: [String]) {
        
        let message = messages
            .joined(
                separator: messageSeparator
            )
            .truncating(
                length: messageLengthLimit,
                trailing: messageTrailing
            )
        
        os_log(
            "%{private}s",
            log: log.osLog ?? .default,
            type: type.osLogType,
            message
        )
    }
}

private extension LogType {
    
    // MARK: - OSLogType
    
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .default:
            return .default
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }
}

extension Log {
    
    // MARK: - OSLog
    
    var osLog: OSLog? {
        guard let subsystem = Bundle.main.bundleIdentifier else {
            return nil
        }
        
        return OSLog(subsystem: subsystem, category: self.rawValue)
    }
}
