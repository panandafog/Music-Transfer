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

    func testSharedTracksComparison() throws {
        let lhs = SharedTrack(id: "456246001", artists: ["Boris Brejcha"], title: "Never Look Back (Radio Edit) #2 [REALTONES™]", durationS: 22)
        
        var rhs = lhs
        XCTAssertTrue(lhs ~= rhs)
        
        rhs = SharedTrack(id: "456246001", artists: ["Boris Brejcha"], title: "Never Look Back (Radio Edit)", durationS: 22)
        XCTAssertTrue(lhs ~= rhs)
        
        rhs = SharedTrack(id: "124541231", artists: ["Boris Brejcha"], title: "Never Look Back (Radio Edit)", durationS: 23)
        XCTAssertTrue(lhs ~= rhs)
        
        rhs = SharedTrack(id: "456246001", artists: ["Boris Brejcha"], title: "Never Look Back", durationS: 22)
        XCTAssertTrue(lhs ~= rhs)
    }
    
    func testSharedTrackTitleClearing() throws {
        XCTAssertEqual(SharedTrack.clearTitle("Never Look Back (Radio Edit)"), "Never Look Back")
    }
    
    func testSharedTrackTitlesComparison() throws {
        XCTAssertTrue(SharedTrack.titlesAreEqual(lhs: "Never Look Back (Radio Edit)", rhs: "Never Look Back"))
    }
}
