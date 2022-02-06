//
//  MusicTransferTests__iOS_.swift
//  MusicTransferTests (iOS)
//
//  Created by panandafog on 05.02.2022.
//

@testable import Music_Transfer
import XCTest

class Tests: XCTestCase {

    func testExample() {
        XCTAssertTrue(
            SharedTrack(
                id: "abcd1",
                artists: [
                    ""
                ],
                title: "name",
                duration: 60,
                servicesData: []
            ) ~= SharedTrack(
                id: "abcd2",
                artists: [
                    ""
                ],
                title: "name",
                duration: 60,
                servicesData: []
            )
        )
    }
}
