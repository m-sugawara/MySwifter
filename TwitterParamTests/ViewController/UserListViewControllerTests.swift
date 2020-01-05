//
//  UserListViewControllerTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2020/01/01.
//  Copyright © 2020 sugawar. All rights reserved.
//

import XCTest

@testable import TwitterParam

class UserListViewControllerTests: XCTestCase {

    private var viewController: UserListViewController!

    override func setUp() {
        viewController = UserListViewController.makeInstance()
    }

    override func tearDown() {
        viewController = nil
    }

    func testExample() {
        viewController.loadView()
        XCTAssertNotNil(viewController.view)
    }

}
