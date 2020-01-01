//
//  UserHelperTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2019/12/30.
//  Copyright © 2019 sugawar. All rights reserved.
//

import XCTest
import SwifteriOS

@testable import TwitterParam

class UserHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        UserHelper.removeUserToken()
    }

    func testSaveUserToken() {
        let key = "testKey"
        let secret = "testSecret"
        let sampleData = Credential.OAuthAccessToken(key: key, secret: secret)
        UserHelper.saveUserToken(data: sampleData)

        let credential = UserHelper.fetchUserToken()
        let expectedCredential = Credential.OAuthAccessToken(key: key, secret: secret)

        XCTAssertEqual(expectedCredential.key, credential?.accessToken?.key)
        XCTAssertEqual(expectedCredential.secret, credential?.accessToken?.secret)
    }

    func testRemoveStoredUserToken() {
        let key = "testKey"
        let secret = "testSecret"
        let sampleData = Credential.OAuthAccessToken(key: key, secret: secret)
        UserHelper.saveUserToken(data: sampleData)

        UserHelper.removeUserToken()

        let credential = UserHelper.fetchUserToken()

        XCTAssertNil(credential)
    }
}
