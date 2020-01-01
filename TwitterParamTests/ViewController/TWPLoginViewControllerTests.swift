//
//  TWPLoginViewControllerTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2020/01/01.
//  Copyright © 2020 sugawar. All rights reserved.
//

import XCTest

@testable import TwitterParam

class TWPLoginViewControllerTests: XCTestCase {

    private var viewController: TWPLoginViewController!

    override func setUp() {
        viewController = TWPLoginViewController.makeInstance()
    }

    override func tearDown() {
        viewController = nil
    }

    func testExample() {
        viewController.loadView()
        XCTAssertNotNil(viewController.view)
    }

}
