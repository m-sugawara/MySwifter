//
//  DateHelperTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2020/03/07.
//  Copyright © 2020 sugawar. All rights reserved.
//

import XCTest
import SwifteriOS

@testable import TwitterParam

class DateHelperTests: XCTestCase {

    private var dateHelper: DateHelper!

    override func setUp() {
        super.setUp()
        dateHelper = DateHelper()
    }

    override func tearDown() {
        super.tearDown()
        dateHelper = nil
    }

    func testDateToString() {
        let sampleDate = Date(timeIntervalSince1970: 1267619326) // 2010/3/3 21:28:46
        let string = dateHelper.dateToString(date: sampleDate, format: "yyyy/MM/dd HH:mm:ss")

        let expected = "2010/03/03 21:28:46"
        XCTAssertEqual(expected, string)
    }

    func testDiffDate() {
        let sampleDate = Date(timeIntervalSince1970: 1267619326) // 2010/3/3 21:28:46
        let otherDate = Date(timeIntervalSince1970: 1299155326) // 2011/3/3 21:28:46

        let diffText = dateHelper.formattedDiffText(date: sampleDate, since: otherDate)

        let expected = "365 days"
        XCTAssertEqual(expected, diffText)
    }

    func testDiffHour() {
        let sampleDate = Date(timeIntervalSince1970: 1267619326) // 2010/3/3 21:28:46
        let otherDate = Date(timeIntervalSince1970: 1267648126) // 2011/3/4 05:28:46

        let diffText = dateHelper.formattedDiffText(date: sampleDate, since: otherDate)

        let expected = "8 hours"
        XCTAssertEqual(expected, diffText)
    }

    func testDiffMinute() {
        let sampleDate = Date(timeIntervalSince1970: 1267619326) // 2010/3/3 21:28:46
        let otherDate = Date(timeIntervalSince1970: 1267620646) // 2011/3/3 21:50:46

        let diffText = dateHelper.formattedDiffText(date: sampleDate, since: otherDate)

        let expected = "22 minutes"
        XCTAssertEqual(expected, diffText)
    }

    func testDiffSecond() {
        let sampleDate = Date(timeIntervalSince1970: 1267619326) // 2010/3/3 21:28:46
        let otherDate = Date(timeIntervalSince1970: 1267619338) // 2011/3/3 21:28:58

        let diffText = dateHelper.formattedDiffText(date: sampleDate, since: otherDate)

        let expected = "12 sec"
        XCTAssertEqual(expected, diffText)
    }

}
