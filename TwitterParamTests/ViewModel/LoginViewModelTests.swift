//
//  LoginViewModelTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2020/01/01.
//  Copyright © 2020 sugawar. All rights reserved.
//

import XCTest

@testable import TwitterParam

class LoginViewModelTests: XCTestCase {

    private var viewModel: LoginViewModel!

    override func setUp() {
        viewModel = LoginViewModel()
    }

    override func tearDown() {
        viewModel = nil
    }

    func testLoginActionFailure() {
        let expectation = XCTestExpectation()

        viewModel.statusSignal.observeValues { status in
            switch status {
            case .ready:
                XCTAssertTrue(false)
                expectation.fulfill()
            case .logined:
                XCTAssertTrue(false)
                expectation.fulfill()
            case .failed(let error):
                XCTAssertNotNil(error)

                let expected = LoginViewModel.LoginError().message
                XCTAssertEqual(expected, error.message)
                expectation.fulfill()
            }
        }
        _ = viewModel.loginAction.apply().start()

        wait(for: [expectation], timeout: 2.0)
    }
}