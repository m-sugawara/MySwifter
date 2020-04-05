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

    var userHelper: UserHelper!

    override func setUp() {
        userHelper = UserHelper()
    }

    override func tearDown() {
        userHelper.removeUserToken()
    }

    func testSaveUserToken() {
        let key = "testKey"
        let secret = "testSecret"
        let sampleData = Credential.OAuthAccessToken(key: key, secret: secret)
        userHelper.saveUserToken(data: sampleData)

        let credential = userHelper.fetchUserToken()
        let expectedCredential = Credential.OAuthAccessToken(key: key, secret: secret)

        XCTAssertEqual(expectedCredential.key, credential?.accessToken?.key)
        XCTAssertEqual(expectedCredential.secret, credential?.accessToken?.secret)
    }

    func testRemoveStoredUserToken() {
        let key = "testKey"
        let secret = "testSecret"
        let sampleData = Credential.OAuthAccessToken(key: key, secret: secret)
        userHelper.saveUserToken(data: sampleData)

        userHelper.removeUserToken()

        let credential = userHelper.fetchUserToken()

        XCTAssertNil(credential)
    }
}
