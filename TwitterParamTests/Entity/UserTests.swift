//
//  UserTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2019/12/22.
//  Copyright © 2019 sugawar. All rights reserved.
//

import XCTest
import SwifteriOS

@testable import TwitterParam

class UserTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSameUserIds() {
        let first = User(userId: "1")
        let expected = User(userId: "1")

        XCTAssertEqual(first, expected)
    }

    func testDifferentUserIds() {
        let first = User(userId: "1")
        let expected = User(userId: "2")

        XCTAssertNotEqual(first, expected)
    }

    func testScreenNameWithAt() {
        let user = User(userId: "1", screenName: "TestUser")
        let expected = "@TestUser"

        XCTAssertEqual(user.screenNameWithAt, expected)
    }

    func testScreenNameWithAtEmpty() {
        let user = User(userId: "1")
        let expected = ""

        XCTAssertEqual(user.screenNameWithAt, expected)
    }

    func testImageURL() {
        let url = "https://abc.com"
        let user = User(userId: "1", profileImageUrl: url)
        let expected = url

        XCTAssertEqual(user.profileImageUrlString, expected)
    }

    func testLoadNoDataJSON() {
        let json: [String: JSON] = [:]
        let user = User(dictionary: json)

        XCTAssertEqual(user.userId, "")
        XCTAssertEqual(user.name, "")
        XCTAssertEqual(user.screenName, "")
        XCTAssertEqual(user.profileImageUrl, nil)
        XCTAssertEqual(user.following, false)
        XCTAssertEqual(user.friendsCount, 0)
        XCTAssertEqual(user.followersCount, 0)
    }

    func testLoadFullJSON() {
        let json: [String: JSON] = [
            "id_str": JSON(stringLiteral: "1"),
            "name": JSON(stringLiteral: "my name"),
            "screen_name": JSON(stringLiteral: "my screen name"),
            "profile_image_url": JSON(stringLiteral: "http://myimage.com"),
            "following": JSON(booleanLiteral: true),
            "friends_count": JSON(integerLiteral: 99),
            "followers_count": JSON(integerLiteral: 100)
        ]
        let user = User(dictionary: json)

        XCTAssertEqual(user.userId, "1")
        XCTAssertEqual(user.name, "my name")
        XCTAssertEqual(user.screenName, "my screen name")
        XCTAssertEqual(user.profileImageUrl, URL(string: "http://myimage.com"))
        XCTAssertEqual(user.following, true)
        XCTAssertEqual(user.friendsCount, 99)
        XCTAssertEqual(user.followersCount, 100)
    }

}
