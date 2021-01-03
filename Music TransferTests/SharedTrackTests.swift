//
//  Music_TransferTests.swift
//  Music TransferTests
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import XCTest
@testable import Music_Transfer

class SharedTrackTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSharedTracksWeakComparison() throws {
        var lhs = SharedTrack(id: "456246001", artists: ["Boris Brejcha"], title: "Never Look Back (Radio Edit) #2 [REALTONES™]", durationS: 22)
        
        var rhs = lhs
        XCTAssertTrue(lhs ~= rhs)
        
        rhs = SharedTrack(id: "456246001", artists: ["Boris Brejcha"], title: "Never Look Back (Radio Edit)", durationS: 22)
        XCTAssertTrue(lhs ~= rhs)
        
        rhs = SharedTrack(id: "124541231", artists: ["Boris Brejcha"], title: "Never Look Back (Radio Edit)", durationS: 23)
        XCTAssertTrue(lhs ~= rhs)
        
        rhs = SharedTrack(id: "456246001", artists: ["Boris Brejcha"], title: "Never Look Back", durationS: 22)
        XCTAssertTrue(lhs ~= rhs)
        
        
        lhs = SharedTrack(id: "722tgOgdIbNe3BEyLnejw4", artists: ["Kanye West"], title: "Black Skinhead", durationS: 188)
        rhs = SharedTrack(id: "722tgOgdIbNe3BEyLnejw4", artists: ["Different"], title: "Black Skinhead (explicit) (Complete version originally performed by Kanye West)", durationS: 188)
        XCTAssertTrue(lhs ~= rhs)
        
        lhs = SharedTrack(id: "722tgOgdIbNe3BEyLnejw4", artists: ["Kanye East"], title: "Black Skinhead", durationS: 188)
        XCTAssertFalse(lhs ~= rhs)
        
        
        lhs = SharedTrack(id: "456240049", artists: ["Boris Brejcha"], title: "Never Look Back", durationS: 220)
        rhs = SharedTrack(id: "2Zl7BFy5LjDaW5tFG3Bv0D", artists: ["Boris Brejcha"], title: "Never Look Back", durationS: 210)
        XCTAssertTrue(lhs ~= rhs)
        
        lhs = SharedTrack(id: "456240049", artists: ["Boris Brejcha"], title: "Never Look Back", durationS: 220)
        rhs = SharedTrack(id: "2Zl7BFy5LjDaW5tFG3Bv0D", artists: ["Boris Brejcha"], title: "Never Look Back", durationS: 22)
        XCTAssertFalse(lhs ~= rhs)
    }
    
    func testSharedTracksStrongComparison() throws {
        var lhs = SharedTrack(id: "722tgOgdIbNe3BEyLnejw4", artists: ["Kanye West"], title: "Black Skinhead", durationS: 188)
        var rhs = SharedTrack(id: "722tgOgdIbNe3BEyLnejw4", artists: ["Different"], title: "Black Skinhead (explicit) (Complete version originally performed by Kanye West)", durationS: 188)
        XCTAssertFalse(lhs == rhs)
        
        lhs = SharedTrack(id: "722tgOgdIbNe3BEyLnejw4", artists: ["Kanye West"], title: "Black Skinhead", durationS: 188)
        rhs = SharedTrack(id: "722tgOgdIbNe3BEyLnejw4", artists: ["Kanye West"], title: "Black Skinhead (explicit) (Complete version originally performed by Kanye West)", durationS: 188)
        XCTAssertTrue(lhs == rhs)
        
        lhs = SharedTrack(id: "456239027", artists: ["Rammstein"], title: "Roter Sand", durationS: 239)
        rhs = SharedTrack(id: "2eQAr4IgxjMEMgBc7Wa4iz", artists: ["Rammstein"], title: "ROTER SAND", durationS: 239)
        XCTAssertTrue(lhs == rhs)
    }
    
    func testSharedTrackDuratinosComparison() throws {
        for percentage in 100 - SharedTrack.durationComparisonInaccuracy...100
            + SharedTrack.durationComparisonInaccuracy {
            XCTAssertTrue(SharedTrack.durationsAreEqual(lhs: percentage, rhs: 100))
        }
        for percentage in 0...100 - SharedTrack.durationComparisonInaccuracy - 1 {
            XCTAssertFalse(SharedTrack.durationsAreEqual(lhs: percentage, rhs: 100))
        }
        XCTAssertFalse(SharedTrack.durationsAreEqual(lhs: 22, rhs: 220))
    }
    
    func testSharedTrackTitleClearing() throws {
        XCTAssertEqual(SharedTrack.clearTitle("Never Look Back (Radio Edit)"), "Never Look Back")
    }
    
    func testSharedTrackTitlesComparison() throws {
        XCTAssertTrue(SharedTrack.titlesAreEqual(lhs: "Never Look Back (Radio Edit)", rhs: "Never Look Back"))
    }
}
