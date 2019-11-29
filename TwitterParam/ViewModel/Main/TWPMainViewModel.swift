//
//  TWPMainViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

import ReactiveCocoa
import ReactiveSwift

class TWPMainViewModel {
    
    dynamic var tapCount: NSInteger = 0
    dynamic var tweets: [TWPTweet] = [TWPTweet]()
    
    var inputtingTweet: MutableProperty<String> = MutableProperty<String>("")
    var selectingIndex: Int?
    
    // because to feed update singal called many times, signal set a variable.
    private var _feedUpdateButtonSignal: Action<Void, Void, Error>?
    
    // MARK: - Deinit
    deinit {
        print("MainViewModel deinit")
    }
    
    // MARK: - Public Methods
    func selectingTweetScreenName() -> String? {
        guard let selectingIndex = selectingIndex else {
            return nil
        }
        let selectingTweet = self.tweets[selectingIndex]
        return selectingTweet.user?.screenName
    }
    
    // MARK: - RACCommands
    // MARK: - OAuth
    var oauthButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> { _ -> SignalProducer<Void, Error> in
            return TWPTwitterAPI.shared.twitterAuthorizeWithOAuth()
        }
    }

    // MARK: - Account
    var accountButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> { _ in
            return TWPTwitterAPI.shared.twitterAuthorizeWithAccount()
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
                observer.sendInterrupted()
                return
            }
            TWPTwitterAPI.shared.getStatusesHomeTimeline().startWithResult { result in
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
                    observer.sendInterrupted()
                    return
                }
                var isReplyToStatusID: String?
                if let index = self.selectingIndex, index < self.tweets.count {
                    isReplyToStatusID = self.tweets[index].tweetID
                }
                TWPTwitterAPI.shared.postStatusUpdate(status: self.inputtingTweet.value, inReplyToStatusID: isReplyToStatusID).startWithResult { result in
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
                    observer.sendInterrupted()
                    return
            }
            let tweet = self.tweets[index]

            // if selected tweet hasn't been retweeted yet, try to retweet
            if tweet.retweeted != true {
                TWPTwitterAPI.shared.postStatusRetweet(with: tweet.tweetID!, trimUser: false).startWithResult { result in
                    switch result {
                    case .success:
                        self.markAsRetweeted(true, at: index)
                        observer.sendCompleted()
                    case .failure(let error):
                        observer.send(error: error)
                    }
                }
            } else {
                TWPTwitterAPI.shared.getCurrentUserRetweetID(with: tweet.tweetID!).startWithResult { result in
                    switch result {
                    case .success(let retweetId):
                        TWPTwitterAPI.shared.postStatusesDestroy(with: retweetId, trimUser: false).startWithResult { result in
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
        let newTweet = tweets[index]
        if retweeted {
            newTweet.retweeted = true
            newTweet.retweetCount = newTweet.retweetCount! + 1
        } else {
            newTweet.retweeted = false
            newTweet.retweetCount = newTweet.retweetCount! - 1
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
                    observer.sendInterrupted()
                    return
            }
            let tweet = self.tweets[index]

            if tweet.favorited != true {
                TWPTwitterAPI.shared.postCreateFavorite(with: tweet.tweetID!, includeEntities: false).startWithResult { result in
                    switch result {
                    case .success:
                        self.markAsFavorited(true, at: index)
                        observer.sendCompleted()
                    case .failure(let error):
                        observer.send(error: error)
                    }
                }
            } else {
                TWPTwitterAPI.shared.postDestroyFavorite(with: tweet.tweetID!, includeEntities: false).startWithResult { result in
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
        let newTweet = tweets[index]
        if favorited {
            newTweet.favorited = true
            newTweet.favoriteCount = newTweet.favoriteCount! + 1
        } else {
            newTweet.favorited = false
            newTweet.favoriteCount = newTweet.favoriteCount! - 1
        }
        tweets[index] = newTweet
    }
}
