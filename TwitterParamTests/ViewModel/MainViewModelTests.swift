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

    func testDefaultTextNil() {
        let result = viewModel.defaultText(withScreenName: nil)
        let expected = ""

        XCTAssertEqual(expected, result)
    }

    func testDefaultTextEmpty() {
        let result = viewModel.defaultText(withScreenName: "")
        let expected = ""

        XCTAssertEqual(expected, result)
    }

    func testDefaultText() {
        let result = viewModel.defaultText(withScreenName: "test")
        let expected = "@test: "

        XCTAssertEqual(expected, result)
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

        viewModel.eventsSignal.observeValues { event in
            switch event {
            case .failedToRequest(let error):
                XCTAssertNotNil(error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToLoadFeed, error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToLoadFeed.message, error.message)
                expectation.fulfill()
            default:
                XCTAssertTrue(false)
                expectation.fulfill()
            }
        }

        viewModel.updateFeed()

        wait(for: [expectation], timeout: 2.0)
    }

    func testTweetButtonAction() {
        let expectation = XCTestExpectation()

        viewModel.eventsSignal.observeValues { event in
            switch event {
            case .failedToRequest(let error):
                XCTAssertNotNil(error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToPostTweet, error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToPostTweet.message, error.message)
                expectation.fulfill()
            default:
                XCTAssertTrue(false)
                expectation.fulfill()
            }
        }

        viewModel.postTweet()

        wait(for: [expectation], timeout: 2.0)
    }

    func testRetweetInvalidIndex() {
        let expectation = XCTestExpectation()

        viewModel.eventsSignal.observeValues { event in
            switch event {
            case .failedToRequest(let error):
                XCTAssertNotNil(error)
                XCTAssertEqual(MainViewModel.MainViewModelError.indexOutOfRange, error)
                XCTAssertEqual(MainViewModel.MainViewModelError.indexOutOfRange.message, error.message)
                expectation.fulfill()
            default:
                XCTAssertTrue(false)
                expectation.fulfill()
            }
        }

        viewModel.postRetweet(withIndex: 0)

        wait(for: [expectation], timeout: 2.0)
    }

    func testRetweetFailedToPost() {
        let expectation = XCTestExpectation()

        viewModel.eventsSignal.observeValues { event in
            switch event {
            case .failedToRequest(let error):
                XCTAssertNotNil(error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToPostRetweet, error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToPostRetweet.message, error.message)
                expectation.fulfill()
            default:
                XCTAssertTrue(false)
                expectation.fulfill()
            }
        }

        addMockTweet()
        viewModel.postRetweet(withIndex: 0)

        wait(for: [expectation], timeout: 2.0)
    }

    func testRetweetFailedToPostDestroy() {
        let expectation = XCTestExpectation()

        viewModel.eventsSignal.observeValues { event in
            switch event {
            case .failedToRequest(let error):
                XCTAssertNotNil(error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToPostRetweet, error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToPostRetweet.message, error.message)
                expectation.fulfill()
            default:
                XCTAssertTrue(false)
                expectation.fulfill()
            }
        }

        addMockTweet(retweeted: false)
        viewModel.postRetweet(withIndex: 0)

        wait(for: [expectation], timeout: 2.0)
    }

    func testFavoriteInvalidIndex() {
        let expectation = XCTestExpectation()

        viewModel.eventsSignal.observeValues { event in
            switch event {
            case .failedToRequest(let error):
                XCTAssertNotNil(error)
                XCTAssertEqual(MainViewModel.MainViewModelError.indexOutOfRange, error)
                XCTAssertEqual(MainViewModel.MainViewModelError.indexOutOfRange.message, error.message)
                expectation.fulfill()
            default:
                XCTAssertTrue(false)
                expectation.fulfill()
            }
        }

        viewModel.postFavorite(withIndex: 0)

        wait(for: [expectation], timeout: 2.0)
    }

    func testFavoriteFailedToPost() {
        let expectation = XCTestExpectation()

        viewModel.eventsSignal.observeValues { event in
            switch event {
            case .failedToRequest(let error):
                XCTAssertNotNil(error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToPostFavorite, error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToPostFavorite.message, error.message)
                expectation.fulfill()
            default:
                XCTAssertTrue(false)
                expectation.fulfill()
            }
        }

        addMockTweet()
        viewModel.postFavorite(withIndex: 0)

        wait(for: [expectation], timeout: 2.0)
    }

    func testFavoriteFailedToPostDestroy() {
        let expectation = XCTestExpectation()

        viewModel.eventsSignal.observeValues { event in
            switch event {
            case .failedToRequest(let error):
                XCTAssertNotNil(error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToPostFavorite, error)
                XCTAssertEqual(MainViewModel.MainViewModelError.failedToPostFavorite.message, error.message)
                expectation.fulfill()
            default:
                XCTAssertTrue(false)
                expectation.fulfill()
            }
        }

        addMockTweet(favorited: true)
        viewModel.postFavorite(withIndex: 0)

        wait(for: [expectation], timeout: 2.0)
    }

    private func addMockTweet(retweeted: Bool = false, favorited: Bool = false) {
        let tweet = Tweet(tweetId: "1", text: "test", user: nil, retweeted: retweeted, favorited: favorited)
        viewModel.appendTweet(tweet)
    }
}
