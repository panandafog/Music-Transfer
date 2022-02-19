//
//  TracksComparator.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 04.02.2022.
//

import Foundation

enum TracksComparator {
    
    enum ComparationMethod {
        case levenshtein
        case inclusions
    }
    
    static let defaultComparationMethod: ComparationMethod = .levenshtein
    
    static let titlesComparationAccuracy = 0.9
    static let durationsComparationInfelicity = 0.1
    
    static func compare(
        _ lhs: SharedTrack,
        _ rhs: SharedTrack,
        method: ComparationMethod
    ) -> Bool {
        switch method {
        case .levenshtein:
            return compareUsingLevenstein(lhs, rhs)
        case .inclusions:
            return compareUsingInclusions(lhs, rhs)
        }
    }
    
    // MARK: - Comparation methods
    
    private static func compareUsingLevenstein(
        _ lhs: SharedTrack,
        _ rhs: SharedTrack
    ) -> Bool {
        let lhsString = lhs.comparationString
        let rhsString = rhs.comparationString
        
        let stringsAccuracy = lhsString.levenshteinAccuracy(rhsString)
        
        let durationsAreEqual: Bool?
        if let lhsDuration = lhs.duration, let rhsDuration = rhs.duration {
            durationsAreEqual = checkDurationsEquality(lhsDuration, rhsDuration)
        } else {
            durationsAreEqual = nil
        }
        
        let result = (stringsAccuracy >= titlesComparationAccuracy) && (durationsAreEqual ?? true)
        
        Logger.write(
            to: .tracksComparation,
            "Tracks compared",
            "Lhs: \(lhs.descriptionString)",
            "Rhs: \(rhs.descriptionString)",
            "lhsString: \(lhsString)",
            "rhsString: \(rhsString)",
            "stringsAccuracy: \(stringsAccuracy)",
            "durationsAreEqual: \(String(describing: durationsAreEqual))",
            "result: \(result)"
        )
        
        return result
    }
    
    private static func compareUsingInclusions(
        _ lhs: SharedTrack,
        _ rhs: SharedTrack
    ) -> Bool {
        func titlesAreEqual(lhs: SharedTrack, rhs: SharedTrack) -> Bool {
            let clearLhs = lhs.clearTitle.lowercased()
            let clearRhs = rhs.clearTitle.lowercased()
            
            return rhs.title.lowercased().contains(clearLhs)
            || lhs.title.lowercased().contains(clearRhs)
            || lhs.title.lowercased() == rhs.title.lowercased()
        }
        
        guard !lhs.artists.isEmpty && !rhs.artists.isEmpty else {
            return false
        }
        
        var lhsArtists = [String]()
        lhs.artists.forEach {
            lhsArtists.append($0.lowercased())
        }
        
        var rhsArtists = [String]()
        rhs.artists.forEach {
            rhsArtists.append($0.lowercased())
        }
        
        var equalArtistsL = true
        let artistL = lhsArtists[0]
        var contains = false
        if rhsArtists.contains(artistL) {
            contains = true
        } else {
            for artistR in rhsArtists {
                if artistR.contains(artistL) {
                    contains = true
                }
            }
        }
        if !contains {
            equalArtistsL = false
        }
        
        var equalArtistsR = true
        let artistR = rhsArtists[0]
        contains = false
        if lhsArtists.contains(artistR) {
            contains = true
        } else {
            for artistL in lhsArtists {
                if artistL.contains(artistR) {
                    contains = true
                }
            }
        }
        if !contains {
            equalArtistsR = false
        }
        
        let equalArtists = equalArtistsL || equalArtistsR
        
        let durationsAreEqual: Bool?
        if let lhsDuration = lhs.duration, let rhsDuration = rhs.duration {
            durationsAreEqual = checkDurationsEquality(lhsDuration, rhsDuration)
        } else {
            durationsAreEqual = nil
        }
        
        return equalArtists && titlesAreEqual(lhs: lhs, rhs: rhs) && (durationsAreEqual ?? true)
    }
    
    private static func checkDurationsEquality(_ lhs: Int, _ rhs: Int) -> Bool {
        guard rhs != 0 else { return lhs == rhs }
        
        let relation = Double(lhs) / Double(rhs)
        
        return 1.0 - durationsComparationInfelicity < relation
        && relation < 1.0 + durationsComparationInfelicity
    }
}

extension SharedTrack {
    
    var comparationString: String {
        let separator = " "
        return [
            artists.joined(separator: separator),
            title
        ].joined(separator: separator)
    }
    
    var clearTitle: String {
        var title = title
        let patterns = ["\\ *\\(.*\\)", "\\ *\\[.*\\]"]
        do {
            for pattern in patterns {
                let regEx = try NSRegularExpression(pattern: pattern, options: [])
                let nsString = title as NSString
                let range = NSRange(location: 0, length: nsString.length)
                title = regEx.stringByReplacingMatches(
                    in: title,
                    options: .withTransparentBounds,
                    range: range,
                    withTemplate: ""
                )
            }
        } catch _ as NSError {
        }
        
        return title
    }
    
    static func ~= (lhs: SharedTrack, rhs: SharedTrack) -> Bool {
        TracksComparator.compare(
            lhs,
            rhs,
            method: TracksComparator.defaultComparationMethod
        )
    }
}

extension String {
    
//    static func ~= (lhs: String, rhs: String) -> Bool {
//        let levenshtein = Double(lhs.levenshtein(rhs))
//        let length = Double(lhs.count)
//        let correctSymbolsNumber = length - levenshtein
//        let accuracy = correctSymbolsNumber / length
//        
//        return accuracy > TracksComparator.comparationAccuracy
//    }
    
    static func compare(lhs: String, rhs: String) -> Double {
        let levenshtein = Double(lhs.levenshteinDistance(rhs))
        let length = Double(lhs.count)
        let correctSymbolsNumber = length - levenshtein
        let accuracy = correctSymbolsNumber / length
        
        return accuracy
    }
    
    func levenshteinAccuracy(_ other: String) -> Double {
        let levenshteinDistance = Double(levenshteinDistance(other))
        let length = Double(count)
        let correctSymbolsNumber = length - levenshteinDistance
        let accuracy = correctSymbolsNumber / length
        
        return accuracy
    }
    
    func levenshteinDistance(_ other: String) -> Int {
        let sCount = self.count
        let oCount = other.count
        
        guard sCount != 0 else {
            return oCount
        }
        
        guard oCount != 0 else {
            return sCount
        }
        
        let line: [Int]  = Array(repeating: 0, count: oCount + 1)
        var mat: [[Int]] = Array(repeating: line, count: sCount + 1)
        
        for index in 0...sCount {
            mat[index][0] = index
        }
        
        for index in 0...oCount {
            mat[0][index] = index
        }
        
        for indexJ in 1...oCount {
            for indexI in 1...sCount {
                if self[indexI - 1] == other[indexJ - 1] {
                    mat[indexI][indexJ] = mat[indexI - 1][indexJ - 1]       // no operation
                } else {
                    let del = mat[indexI - 1][indexJ] + 1         // deletion
                    let ins = mat[indexI][indexJ - 1] + 1         // insertion
                    let sub = mat[indexI - 1][indexJ - 1] + 1     // substitution
                    mat[indexI][indexJ] = min(min(del, ins), sub)
                }
            }
        }
        return mat[sCount][oCount]
    }
}
