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
    dynamic var tweets: NSArray = []
    
    var inputtingTweet: String?
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
        let selectingTweet = self.tweets[selectingIndex] as? TWPTweet
        return selectingTweet?.user?.screenName
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
    var feedUpdateButtonCommand: Command {
        return RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return self!.feedUpdateButtonSignal()
        })
    }
    func feedUpdateButtonSignal() -> RACSignal {
        if (_feedUpdateButtonSignal != nil) {
            return _feedUpdateButtonSignal!
        }

        _feedUpdateButtonSignal = RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                self!.twitterAPI.getStatusesHomeTimelineWithCount(20)?.subscribeNext({ (next) -> Void in
                    self!.tweets = next as! NSArray
                    }, error: { (error) -> Void in
                        subscriber.sendError(error)
                    }, completed: { () -> Void in
                        subscriber.sendNext(nil)
                        subscriber.sendCompleted()
                })
            })
            
            return nil
            })
        
        
        return _feedUpdateButtonSignal!
    }
    
    // logout
    var logoutButtonCommand: RACCommand {
        return RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return self!.logoutButtonSignal()
        })
    }
    func logoutButtonSignal() -> RACSignal {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            return RACDisposable(block: { () -> Void in
            })
        })
    }
    
    // tweet
    var tweetButtonCommand: RACCommand {
        return RACCommand(enabled:self.rac_valuesForKeyPath("inputtingTweet", observer: self
            ).map ({ (next) -> AnyObject! in
                return !(next as! String).isEmpty
            }),
            
            signalBlock: { [weak self] (input) -> RACSignal! in
            return self!.tweetButtonSignal()
        })
    }
    
    func tweetButtonSignal() -> RACSignal {
        return RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
            var inReplyToStatusID:String? = nil
            if (self?.selectingIndex != kNotSelectIndex) {
                var selectingTweet:TWPTweet = self!.tweets[self!.selectingIndex] as! TWPTweet
                inReplyToStatusID = selectingTweet.tweetID
            }
            
            self!.twitterAPI.postStatusUpdate(
                self!.inputtingTweet!,
                inReplyToStatusID: inReplyToStatusID)?.subscribeError({ (error) -> Void in
                subscriber.sendError(error)
            }, completed: { () -> Void in
                subscriber.sendNext(nil)
                subscriber.sendCompleted()
            })
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }
    
    // retweet
    func postStatusRetweetSignalWithIndex(index: Int) -> RACSignal {
        var tweet: TWPTweet = self.tweets[index] as! TWPTweet
        
        return RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
            
            // if haven't retweeted yet, try to retweet
            if (tweet.retweeted != true) {
                self!.twitterAPI.postStatusRetweetWithID(tweet.tweetID!,
                    trimUser: false)?.subscribeError({ (error) -> Void in
                        subscriber.sendError(error)
                    }, completed: { () -> Void in
                        (self!.tweets[index] as! TWPTweet).retweeted = true
                        (self!.tweets[index] as! TWPTweet).retweetCount = (self!.tweets[index] as! TWPTweet).retweetCount! + 1
                        
                        subscriber.sendNext(nil)
                        subscriber.sendCompleted()
                    })
            }
            // if already have retweeted, destroy retweet
            else {
                var retweetID:String?
                
                // 1. get current user's retweetID
                self!.twitterAPI.getCurrentUserRetweetIDWithID(tweet.tweetID!)?.subscribeNext({ (next) -> Void in
                    // if successed, current user's retweetID
                    retweetID = next as? String
                    }, error: { (error) -> Void in
                        subscriber.sendError(error)
                    }, completed: { () -> Void in
                        // 2. destroy current user's retweet
                        self!.twitterAPI.postStatusesDestroyWithID(retweetID!,
                            trimUser: false)!.subscribeNext({ (next) -> Void in
                                }, error: { (error) -> Void in
                                    subscriber.sendError(error)
                                }, completed: { () -> Void in
                                    // 3. this tweet become be NOT retweeted
                                    (self!.tweets[index] as! TWPTweet).retweeted = false
                                    (self!.tweets[index] as! TWPTweet).retweetCount = (self!.tweets[index] as! TWPTweet).retweetCount! - 1
                                    
                                    subscriber.sendNext(nil)
                                    subscriber.sendCompleted()
                            })
                })
            }
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }
    
    // favorite
    func postFavoriteSignalWithIndex(index: Int) -> RACSignal {
        var tweet: TWPTweet = self.tweets[index] as! TWPTweet
        
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
