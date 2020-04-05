//
//  MainViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

import ReactiveSwift

class MainViewModel {

    enum MainViewModelError: Error {
        case failedToLoadFeed
        case failedToPostTweet
        case failedToPostRetweet
        case failedToPostFavorite
        case indexOutOfRange

        var message: String {
            switch self {
            case .failedToLoadFeed:
                return "Failed to load feed"
            case .failedToPostTweet:
                return "Failed to post tweet"
            case .failedToPostRetweet:
                return "Failed to post retweet"
            case .failedToPostFavorite:
                return "Failed to post favorite"
            case .indexOutOfRange:
                return "Action has interupted because index out of range"
            }
        }
    }

    enum Event {
        case startToRequest
        case loadedFeed
        case postedTweet
        case postedRetweet
        case postedFavorite
        case failedToRequest(error: MainViewModelError)
    }

    var twitterAPI: TwitterAPI!
    var userHelper: UserHelper!

    private let (_eventsSignal, eventsObserver) = Signal<Event, Never>.pipe()
    var eventsSignal: Signal<Event, Never> {
        return _eventsSignal
    }

    var isLoggedIn: Bool {
        return userHelper.isLoggedIn()
    }
    private(set) var tweets = [Tweet]()

    var inputtingTweet = MutableProperty<String>("")

    // MARK: - Deinit
    deinit {
        print("MainViewModel deinit")
    }

    // MARK: - RACCommands
    // MARK: - OAuth
    var oauthButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> { _ -> SignalProducer<Void, Error> in
            return self.twitterAPI.twitterAuthorizeWithOAuth()
        }
    }

    // MARK: - Account
    var accountButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> { _ in
            return self.twitterAPI.twitterAuthorizeWithAccount()
        }
    }

    // MARK: - Feed update
    func updateFeed() {
        twitterAPI.getStatusesHomeTimeline().startWithResult { [weak self] result in
            switch result {
            case .success(let tweets):
                self?.tweets = tweets
                self?.eventsObserver.send(value: .loadedFeed)
            case .failure(let error):
                print(error)
                self?.eventsObserver.send(value: .failedToRequest(error: .failedToLoadFeed))
            }
        }
    }

    // MARK: - Tweet
    func postTweet(withIndex index: Int? = nil) {
        var isReplyToStatusID: String?
        if let index = index, index < tweets.count {
            isReplyToStatusID = tweets[index].tweetId
        }
        twitterAPI.postStatusUpdate(
            status: inputtingTweet.value,
            inReplyToStatusID: isReplyToStatusID
        ).startWithResult { [weak self] result in
            switch result {
            case .success:
                self?.eventsObserver.send(value: .postedTweet)
            case .failure(let error):
                print("failed to post tweet. \(error)")
                self?.eventsObserver.send(value: .failedToRequest(error: .failedToPostTweet))
            }
        }
    }

    // MARK: - Retweet
    func postRetweet(withIndex index: Int) {
        guard index < tweets.count else {
            eventsObserver.send(value: .failedToRequest(error: .indexOutOfRange))
            return
        }
        let tweet = tweets[index]

        // if selected tweet hasn't been retweeted yet, try to retweet
        if tweet.retweeted != true {
            twitterAPI.postStatusRetweet(
                with: tweet.tweetId,
                trimUser: false
            ).startWithResult { [weak self] result in
                    switch result {
                    case .success:
                        self?.markAsRetweeted(true, at: index)
                        self?.eventsObserver.send(value: .postedRetweet)
                    case .failure(let error):
                        print("failed to post retweet: \(error)")
                        self?.eventsObserver.send(value: .failedToRequest(error: .failedToPostRetweet))
                    }
            }
        } else {
            twitterAPI.getCurrentUserRetweetId(
                with: tweet.tweetId
            ).startWithResult { [weak self] result in
                    switch result {
                    case .success(let retweetId):
                        self?.twitterAPI.postStatusesDestroy(
                            with: retweetId,
                            trimUser: false
                        ).startWithResult { [weak self]  result in
                            switch result {
                            case .success:
                                self?.markAsRetweeted(false, at: index)
                                self?.eventsObserver.send(value: .postedRetweet)
                            case .failure(let error):
                                print("failed to destroy current user's retweet: \(error)")
                                self?.eventsObserver.send(
                                    value:.failedToRequest(error: .failedToPostRetweet))
                            }
                        }
                    case .failure(let error):
                        print("failed to get current user's retweet: \(error)")
                        self?.eventsObserver.send(value: .failedToRequest(error: .failedToPostRetweet))
                    }
            }

        }
    }

    private func markAsRetweeted(_ retweeted: Bool, at index: Int) {
        guard tweets.count > index else { return }
        var newTweet = tweets[index]
        if retweeted {
            newTweet.retweeted = true
            newTweet.retweetCount += 1
        } else {
            newTweet.retweeted = false
            newTweet.retweetCount -= 1
        }
        tweets[index] = newTweet
    }

    // MARK: - Favorite
    func postFavorite(withIndex index: Int) {
        guard index < tweets.count else {
            eventsObserver.send(value: .failedToRequest(error: .indexOutOfRange))
            return
        }
        let tweet = tweets[index]

        if tweet.favorited != true {
            twitterAPI.postCreateFavorite(
                with: tweet.tweetId,
                includeEntities: false
            ).startWithResult { [weak self] result in
                switch result {
                case .success:
                    self?.markAsFavorited(true, at: index)
                    self?.eventsObserver.send(value: .postedFavorite)
                case .failure(let error):
                    print("failed to post favorite: \(error)")
                    self?.eventsObserver.send(value: .failedToRequest(error: .failedToPostFavorite))
                }
            }
        } else {
            twitterAPI.postDestroyFavorite(
                with: tweet.tweetId,
                includeEntities: false
            ).startWithResult { [weak self] result in
                switch result {
                case .success:
                    self?.markAsFavorited(false, at: index)
                    self?.eventsObserver.send(value: .postedFavorite)
                case .failure(let error):
                    print("failed to destory favorite: \(error)")
                    self?.eventsObserver.send(value: .failedToRequest(error: .failedToPostFavorite))
                }
            }
        }
    }

    private func markAsFavorited(_ favorited: Bool, at index: Int) {
        guard tweets.count > index else { return }
        var newTweet = tweets[index]
        if favorited {
            newTweet.favorited = true
            newTweet.favoriteCount += 1
        } else {
            newTweet.favorited = false
            newTweet.favoriteCount += 1
        }
        tweets[index] = newTweet
    }

    // MARK: - Logout
    func logout() {
        userHelper.removeUserToken()
    }

    // MARK: - Text decoration
    func defaultText(withScreenName screenName: String?) -> String {
        guard let screenName = screenName, !screenName.isEmpty else {
            return ""
        }
        return "@" + screenName + ": "
    }

    // MARK: - For Test(remove later)
    func appendTweet(_ tweet: Tweet) {
        tweets.append(tweet)
    }
}
