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
        case interrupted

        var message: String {
            switch self {
            case .failedToLoadFeed:
                return "Failed to load feed"
            case .failedToPostTweet:
                return "Failed to post tweet"
            case .interrupted:
                return "Action has interupted"
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

    private let (_eventsSignal, eventsObserver) = Signal<Event, Never>.pipe()
    var eventsSignal: Signal<Event, Never> {
        return _eventsSignal
    }

    var isLoggedIn: Bool {
        return UserHelper.isLoggedIn()
    }
    var tweets = [Tweet]()

    var inputtingTweet = MutableProperty<String>("")
    var selectingIndex: Int?
    var selectingTweet: Tweet? {
        guard let index = selectingIndex,
            tweets.count > index else { return nil }
        return tweets[index]
    }

    // MARK: - Deinit
    deinit {
        print("MainViewModel deinit")
    }

    // MARK: - RACCommands
    // MARK: - OAuth
    var oauthButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> { _ -> SignalProducer<Void, Error> in
            return TwitterAPI.shared.twitterAuthorizeWithOAuth()
        }
    }

    // MARK: - Account
    var accountButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> { _ in
            return TwitterAPI.shared.twitterAuthorizeWithAccount()
        }
    }

    // MARK: - Feed update
    func updateFeed() {
        TwitterAPI.shared.getStatusesHomeTimeline().startWithResult { [weak self] result in
            switch result {
            case .success(let tweets):
                self?.tweets = tweets
                self?.eventsObserver.send(value: .loadedFeed)
            case .failure(let error):
                print(error)
                self?.tweets.removeAll()
                self?.eventsObserver.send(value: .failedToRequest(error: .failedToLoadFeed))
            }
        }
    }

    // MARK: - Tweet
    func postTweet() {
        var isReplyToStatusID: String?
        if let index = selectingIndex, index < tweets.count {
            isReplyToStatusID = tweets[index].tweetId
        }
        TwitterAPI.shared.postStatusUpdate(
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
    func postRetweetAction(with index: Int) -> Action<Void, Void, Error> {
        return Action<Void, Void, Error> {
            return self.postRetweet(with: index)
        }
    }

    func postRetweet(with index: Int) -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, lifetime in
            guard let self = self, !lifetime.hasEnded,
                self.tweets.count > index else {
                    observer.send(error: MainViewModelError.interrupted)
                    observer.sendInterrupted()
                    return
            }
            let tweet = self.tweets[index]

            // if selected tweet hasn't been retweeted yet, try to retweet
            if tweet.retweeted != true {
                TwitterAPI.shared.postStatusRetweet(
                    with: tweet.tweetId, trimUser: false).startWithResult { result in
                    switch result {
                    case .success:
                        self.markAsRetweeted(true, at: index)
                        observer.sendCompleted()
                    case .failure(let error):
                        observer.send(error: error)
                    }
                }
            } else {
                TwitterAPI.shared.getCurrentUserRetweetId(
                    with: tweet.tweetId).startWithResult { result in
                    switch result {
                    case .success(let retweetId):
                        TwitterAPI.shared.postStatusesDestroy(
                            with: retweetId,
                            trimUser: false
                        ).startWithResult { result in
                            switch result {
                            case .success:
                                self.markAsRetweeted(false, at: index)
                                observer.sendCompleted()
                            case .failure(let error):
                                observer.send(error: error)
                            }
                        }
                    case .failure(let error):
                        observer.send(error: error)
                    }
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
    func postFavoriteAction(with index: Int) -> Action<Void, Void, Error> {
        return Action<Void, Void, Error> {
            return self.postFavorite(with: index)
        }
    }

    func postFavorite(with index: Int) -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, lifetime in
            guard let self = self, !lifetime.hasEnded,
                self.tweets.count > index else {
                    observer.send(error: MainViewModelError.interrupted)
                    observer.sendInterrupted()
                    return
            }
            let tweet = self.tweets[index]

            if tweet.favorited != true {
                TwitterAPI.shared.postCreateFavorite(
                    with: tweet.tweetId,
                    includeEntities: false
                ).startWithResult { result in
                    switch result {
                    case .success:
                        self.markAsFavorited(true, at: index)
                        observer.sendCompleted()
                    case .failure(let error):
                        observer.send(error: error)
                    }
                }
            } else {
                TwitterAPI.shared.postDestroyFavorite(
                    with: tweet.tweetId,
                    includeEntities: false
                ).startWithResult { result in
                    switch result {
                    case .success:
                        self.markAsFavorited(false, at: index)
                        observer.sendCompleted()
                    case .failure(let error):
                        self.selectingIndex = nil
                        observer.send(error: error)
                    }
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
        UserHelper.removeUserToken()
    }

    // MARK: - Text decoration
    func defaultText(withScreenName screenName: String?) -> String {
        guard let screenName = screenName, !screenName.isEmpty else {
            return ""
        }
        return "@" + screenName + ": "
    }
}
