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
        // FIXME
        let twitterAPI = TwitterAPI(secrets: TwitterSecrets(consumerKey: "", consumerSecret: ""))
        twitterAPI.userHelper = UserHelper()
        viewModel.setTwitterAPI(twitterAPI)
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
            case .failed(let errorMessage):
                XCTAssertNotNil(errorMessage)

                let expected = APIError.noTwitterAccount.localizedDescription
                XCTAssertEqual(expected, errorMessage)
                expectation.fulfill()
            }
        }
        _ = viewModel.loginAction.apply().start()

        wait(for: [expectation], timeout: 2.0)
    }
}
