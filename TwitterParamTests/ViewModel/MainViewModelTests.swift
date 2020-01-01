//
//  MainViewModelTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2019/12/15.
//  Copyright © 2019 sugawar. All rights reserved.
//

import XCTest

@testable import TwitterParam

class MainViewModelTests: XCTestCase {

    private var viewModel: MainViewModel!

    override func setUp() {
        viewModel = MainViewModel()
    }

    override func tearDown() {
        viewModel = nil
    }

    func testOAuthButtonAction() {
        let expectation = XCTestExpectation()

        viewModel.oauthButtonAction.apply().startWithResult { result in
            switch result {
            case .success:
                XCTAssertTrue(false)
                expectation.fulfill()
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testAccountButtonAction() {
        let expectation = XCTestExpectation()

        viewModel.accountButtonAction.apply().startWithResult { result in
            switch result {
            case .success:
                XCTAssertTrue(false)
                expectation.fulfill()
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFeedUpdateButtonAction() {
        let expectation = XCTestExpectation()

        viewModel.feedUpdateButtonAction.apply().startWithResult { result in
            switch result {
            case .success:
                XCTAssertTrue(false)
                expectation.fulfill()
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testTweetButtonAction() {
        let expectation = XCTestExpectation()

        viewModel.tweetButtonAction.apply().startWithResult { result in
            switch result {
            case .success:
                XCTAssertTrue(false)
                expectation.fulfill()
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testRetweetButtonAction() {
        let expectation = XCTestExpectation()

        viewModel.postRetweetAction(with: 0).apply().startWithResult { result in
            switch result {
            case .success:
                XCTAssertTrue(false)
                expectation.fulfill()
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFavoriteButtonAction() {
        let expectation = XCTestExpectation()

        viewModel.postFavoriteAction(with: 0).apply().startWithResult { result in
            switch result {
            case .success:
                XCTAssertTrue(false)
                expectation.fulfill()
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }
}
