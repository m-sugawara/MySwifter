//
//  UserListViewModelTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2019/12/28.
//  Copyright © 2019 sugawar. All rights reserved.
//

import XCTest

@testable import TwitterParam

class UserListViewModelTests: XCTestCase {

    private var viewModel: UserListViewModel!

    override func setUp() {
        viewModel = UserListViewModel()
        // FIXME
        let userHelper = UserHelper()
        let twitterAPI = TwitterAPI(secrets: TwitterSecrets(consumerKey: "", consumerSecret: ""))
        twitterAPI.userHelper = userHelper
        viewModel.twitterAPI = twitterAPI
    }

    override func tearDown() {
        viewModel = nil
    }

    func testGetUserAction() {
        let expectation = XCTestExpectation()

        viewModel.getUserList(with: "1").startWithResult { result in
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
