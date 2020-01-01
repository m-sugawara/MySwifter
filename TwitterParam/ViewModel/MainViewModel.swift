//
//  MainViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

import ReactiveCocoa
import ReactiveSwift

class MainViewModel {

    enum MainViewModelError: Error {
        case interrupted

        var message: String {
            switch self {
            case .interrupted:
                return "Action has interupted"
            }
        }
    }

    dynamic var tapCount: NSInteger = 0
    dynamic var tweets: [Tweet] = [Tweet]()

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
    var feedUpdateButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> {
            return self.feedUpdate
        }
    }

    var feedUpdate: SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, lifetime in
            guard let self = self, !lifetime.hasEnded else {
                observer.send(error: MainViewModelError.interrupted)
                observer.sendInterrupted()
                return
            }
            TwitterAPI.shared.getStatusesHomeTimeline().startWithResult { result in
                switch result {
                case .success(let tweets):
                    self.tweets = tweets
                case .failure(let error):
                    observer.send(error: error)
                }
            }
        }
    }

    // MARK: - Tweet
    var tweetButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { [weak self] observer, lifetime in
                guard let self = self, !lifetime.hasEnded,
                    !self.inputtingTweet.value.isEmpty else {
                        observer.send(error: MainViewModelError.interrupted)
                        observer.sendInterrupted()
                        return
                }
                var isReplyToStatusID: String?
                if let index = self.selectingIndex, index < self.tweets.count {
                    isReplyToStatusID = self.tweets[index].tweetId
                }
                TwitterAPI.shared.postStatusUpdate(
                    status: self.inputtingTweet.value,
                    inReplyToStatusID: isReplyToStatusID
                ).startWithResult { result in
                    switch result {
                    case .success:
                        observer.sendCompleted()
                    case .failure(let error):
                        observer.send(error: error)
                    }
                }
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
}
