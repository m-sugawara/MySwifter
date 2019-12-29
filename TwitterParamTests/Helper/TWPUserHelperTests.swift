//
//  TWPUserHelperTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2019/12/30.
//  Copyright © 2019 sugawar. All rights reserved.
//

import XCTest
import SwifteriOS

@testable import TwitterParam

class TWPUserHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        TWPUserHelper.removeUserToken()
    }

    func testSaveUserToken() {
        let key = "testKey"
        let secret = "testSecret"
        let sampleData = Credential.OAuthAccessToken(key: key, secret: secret)
        TWPUserHelper.saveUserToken(data: sampleData)

        let credential = TWPUserHelper.fetchUserToken()
        let expectedCredential = Credential.OAuthAccessToken(key: key, secret: secret)

        XCTAssertEqual(expectedCredential.key, credential?.accessToken?.key)
        XCTAssertEqual(expectedCredential.secret, credential?.accessToken?.secret)
    }

    func testRemoveStoredUserToken() {
        let key = "testKey"
        let secret = "testSecret"
        let sampleData = Credential.OAuthAccessToken(key: key, secret: secret)
        TWPUserHelper.saveUserToken(data: sampleData)

        TWPUserHelper.removeUserToken()

        let credential = TWPUserHelper.fetchUserToken()

        XCTAssertNil(credential)
    }
}
