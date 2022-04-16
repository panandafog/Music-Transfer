//
//  DateFormatter.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import Foundation

extension DateFormatter {
    
    static var mt: DateFormatter {
        var mtDateFormatter = DateFormatter()
        mtDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return mtDateFormatter
    }
}
