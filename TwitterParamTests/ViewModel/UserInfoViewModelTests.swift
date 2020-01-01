//
//  UserInfoViewModelTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2019/12/22.
//  Copyright © 2019 sugawar. All rights reserved.
//

import XCTest

@testable import TwitterParam

class UserInfoViewModelTests: XCTestCase {

    private var viewModel: UserInfoViewModel!

    override func setUp() {
        viewModel = UserInfoViewModel()
    }

    override func tearDown() {
        viewModel = nil
    }

    func testGetUserAction() {
        let expectation = XCTestExpectation()

        viewModel.getUserAction.apply().startWithResult { result in
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

    func testGetUserTimeListAction() {
        let expectation = XCTestExpectation()

        viewModel.getUserTimeLineAction.apply().startWithResult { result in
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

    func testGetUserImageListAction() {
        let expectation = XCTestExpectation()

        viewModel.getUserImageListAction.apply().startWithResult { result in
            switch result {
            case .success:
                XCTAssertEqual(self.viewModel.tweets.count, 1)
                expectation.fulfill()
            case .failure:
                XCTAssertTrue(false)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testGetUserFavoritesAction() {
        let expectation = XCTestExpectation()

        viewModel.getUserFavoritesAction.apply().startWithResult { result in
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

    func testFollowAction() {
        let expectation = XCTestExpectation()

        viewModel.followAction.apply().startWithResult { result in
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

    func testUnfollowAction() {
        let expectation = XCTestExpectation()

        viewModel.user = User(userId: "", following: true)
        viewModel.followAction.apply().startWithResult { result in
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
