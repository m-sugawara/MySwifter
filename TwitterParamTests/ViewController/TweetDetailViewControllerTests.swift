//
//  TweetDetailViewControllerTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2020/01/01.
//  Copyright © 2020 sugawar. All rights reserved.
//

import XCTest

@testable import TwitterParam

class TweetDetailViewControllerTests: XCTestCase {

    private var viewController: TweetDetailViewController!

    override func setUp() {
        viewController = TweetDetailViewController.makeInstance()
    }

    override func tearDown() {
        viewController = nil
    }

    func testExample() {
        viewController.loadView()
        XCTAssertNotNil(viewController.view)
    }

}
