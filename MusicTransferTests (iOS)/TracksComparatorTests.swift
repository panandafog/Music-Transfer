//
//  MusicTransferTests__iOS_.swift
//  MusicTransferTests (iOS)
//
//  Created by panandafog on 05.02.2022.
//

@testable import Music_Transfer
import XCTest

class TracksComparatorTests: XCTestCase {
    
    func testComparation1() {
        makeComparation(
            ComparationCase(
                lhs:
                    SharedTrack(
                        id: "abcd1",
                        artists: [
                            ""
                        ],
                        title: "name",
                        duration: 60,
                        servicesData: []
                    ),
                rhs:
                    SharedTrack(
                        id: "abcd1",
                        artists: [
                            ""
                        ],
                        title: "name",
                        duration: 60,
                        servicesData: []
                    ),
                equal: true
            )
        )
    }
    
    func testComparation2() {
        makeComparation(
            ComparationCase(
                lhs:
                    SharedTrack(
                        id: "abcd1",
                        artists: [
                            ""
                        ],
                        title: "name",
                        duration: 60,
                        servicesData: []
                    ),
                rhs:
                    SharedTrack(
                        id: "abcd2",
                        artists: [
                            ""
                        ],
                        title: "name",
                        duration: 60,
                        servicesData: []
                    ),
                equal: true
            )
        )
    }
    
    func testComparation3() {
        makeComparation(
            ComparationCase(
                lhs:
                    SharedTrack(
                        id: "abcd1",
                        artists: [
                            ""
                        ],
                        title: "name",
                        duration: 60,
                        servicesData: []
                    ),
                rhs:
                    SharedTrack(
                        id: "abcd2",
                        artists: [
                            ""
                        ],
                        title: "name",
                        duration: 58,
                        servicesData: []
                    ),
                equal: true
            )
        )
    }
    
    func testComparation4() {
        makeComparation(
            ComparationCase(
                lhs:
                    SharedTrack(
                        id: "abcd1",
                        artists: [
                            ""
                        ],
                        title: "name",
                        duration: 60,
                        servicesData: []
                    ),
                rhs:
                    SharedTrack(
                        id: "abcd2",
                        artists: [
                            ""
                        ],
                        title: "name",
                        duration: 55,
                        servicesData: []
                    ),
                equal: true
            )
        )
    }
    
    func testComparation5() {
        makeComparation(
            ComparationCase(
                lhs:
                    SharedTrack(
                        id: "abcd1",
                        artists: [
                            "very long artist name"
                        ],
                        title: "very long title",
                        duration: 60,
                        servicesData: []
                    ),
                rhs:
                    SharedTrack(
                        id: "abcd2",
                        artists: [
                            "very long artist nama"
                        ],
                        title: "very lung title",
                        duration: 60,
                        servicesData: []
                    ),
                equal: true
            )
        )
    }
    
    func testComparation6() {
        makeComparation(
            ComparationCase(
                lhs:
                    SharedTrack(
                        id: "abcd1",
                        artists: [
                            "very long artist name"
                        ],
                        title: "very long title",
                        duration: 60,
                        servicesData: []
                    ),
                rhs:
                    SharedTrack(
                        id: "abcd2",
                        artists: [
                            "very long artist name"
                        ],
                        title: "another title",
                        duration: 60,
                        servicesData: []
                    ),
                equal: false
            )
        )
    }
    
    func testComparation7() {
        makeComparation(
            ComparationCase(
                lhs:
                    SharedTrack(
                        id: "abcd1",
                        artists: [
                            "very long artist name"
                        ],
                        title: "very long title",
                        duration: 60,
                        servicesData: []
                    ),
                rhs:
                    SharedTrack(
                        id: "abcd2",
                        artists: [
                            "another artist name"
                        ],
                        title: "very long title",
                        duration: 60,
                        servicesData: []
                    ),
                equal: false
            )
        )
    }
    
    private func makeComparation(_ comparationCase: ComparationCase) {
        XCTAssertEqual(
            TracksComparator.compare(
                comparationCase.lhs,
                comparationCase.rhs,
                method: .levenshtein
            ),
            comparationCase.equal
        )
    }
}

extension TracksComparatorTests {
    
    private struct ComparationCase {
        let lhs: SharedTrack
        let rhs: SharedTrack
        let equal: Bool
    }
}
