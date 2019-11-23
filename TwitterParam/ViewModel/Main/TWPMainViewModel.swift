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
    let twitterAPI = TWPTwitterAPI.sharedInstance
    
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
    // oauth
    var oauthButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> { _ -> SignalProducer<Void, Error> in
            return self.twitterAPI.twitterAuthorizeWithOAuth()
        }
    }

    // account
    var accountButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> {
            return self.twitterAPI.twitterAuthorizeWithAccount()
        }
    }
    
    // feed update
    var feedUpdateButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { [weak self] observer, lifetime in
                guard let self = self, !lifetime.hasEnded else {
                    observer.sendInterrupted()
                    return
                }
                self.twitterAPI.getStatusesHomeTimeline().startWithResult { result in
                    switch result {
                    case .success(let tweets):
                        self.tweets = tweets
                    case .failure(let error):
                        observer.send(error: error)
                    }
                }
            }
        }
    }
    
    // logout
    var logoutButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { [weak self] observer, lifetime in
                guard let self = self, !lifetime.hasEnded else {
                    observer.sendInterrupted()
                    return
                }
                self.twitterAPI.logout()
            }
        }
    }

    // tweet
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
                self.twitterAPI.postStatusUpdate(status: self.inputtingTweet.value, inReplyToStatusID: isReplyToStatusID).startWithResult { result in
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
    
    // retweet
    func postStatusRetweetAction(with index: Int) -> Action<Void, Void, Error> {
        return Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { [weak self] observer, lifetime in
                guard let self = self, !lifetime.hasEnded,
                    self.tweets.count > index else {
                        observer.sendInterrupted()
                        return
                }
                let tweet = self.tweets[index]

                // if selected tweet hasn't been retweeted yet, try to retweet
                if tweet.retweeted != true {
                    self.twitterAPI.postStatusRetweet(with: tweet.tweetID!, trimUser: false).startWithResult { result in
                        switch result {
                        case .success:
                            self.markAsRetweeted(true, at: index)
                            observer.sendCompleted()
                        case .failure(let error):
                            observer.send(error: error)
                        }
                    }
                } else {
                    self.twitterAPI.getCurrentUserRetweetID(with: tweet.tweetID!).startWithResult { result in
                        switch result {
                        case .success(let retweetId):
                            self.twitterAPI.postStatusesDestroy(with: retweetId, trimUser: false).startWithResult { result in
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
    
    // favorite
    func postFavoriteSignalWithIndex(index: Int) -> RACSignal {
        var tweet = self.tweets[index]
        
        return RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
            
            // if haven't favorited yet, try to favorite
            if (tweet.favorited != true) {
                self!.twitterAPI.postCreateFavoriteWithID(tweet.tweetID!,
                    includeEntities: false)?.subscribeError({ (error) -> Void in
                        subscriber.sendError(error)
                        }, completed: { () -> Void in
                            (self!.tweets[index] as! TWPTweet).favorited = true
                            (self!.tweets[index] as! TWPTweet).favoriteCount = (self!.tweets[index] as! TWPTweet).favoriteCount! + 1
                            
                            subscriber.sendNext(nil)
                            subscriber.sendCompleted()
                    })
            }
            // if already have favorited, destroy favorite
            else {
                self!.twitterAPI.postDestroyFavoriteWithID(tweet.tweetID!,
                    includeEntities: false)?.subscribeError({ (error) -> Void in
                        subscriber.sendError(error)
                        }, completed: { () -> Void in
                            (self!.tweets[index] as! TWPTweet).favorited = false
                            (self!.tweets[index] as! TWPTweet).favoriteCount = (self!.tweets[index] as! TWPTweet).favoriteCount! - 1
                            
                            subscriber.sendNext(nil)
                            subscriber.sendCompleted()
                    })
            }
            
            return RACDisposable(block: { () -> Void in
            })
        })
        
    }
}
