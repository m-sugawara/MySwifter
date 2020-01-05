//
//  UserInfoViewControllerTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2020/01/01.
//  Copyright © 2020 sugawar. All rights reserved.
//

import XCTest

@testable import TwitterParam

class UserInfoViewControllerTests: XCTestCase {

    private var viewController: UserInfoViewController!

    override func setUp() {
        viewController = UserInfoViewController.makeInstance()
    }

    override func tearDown() {
        viewController = nil
    }

    func testExample() {
        viewController.loadView()
        XCTAssertNotNil(viewController.view)
    }

}
