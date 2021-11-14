//
//  TestsiOS.swift
//  Tests iOS
//
//  Created by panandafog on 07.01.2021.
//

import XCTest

class TestsiOS: XCTestCase {

    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
