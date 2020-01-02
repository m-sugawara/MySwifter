//
//  MainViewControllerTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2020/01/01.
//  Copyright © 2020 sugawar. All rights reserved.
//

import XCTest

@testable import TwitterParam

class MainViewControllerTests: XCTestCase {

    private var viewController: MainViewController!

    override func setUp() {
        viewController = MainViewController.makeInstance()
    }

    override func tearDown() {
        viewController = nil
    }

    func testExample() {
        viewController.loadView()
        XCTAssertNotNil(viewController.view)
    }

}
