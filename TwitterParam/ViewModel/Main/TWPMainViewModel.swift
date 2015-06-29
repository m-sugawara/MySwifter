//
//  TWPMainViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

import ReactiveCocoa

let kNotSelectIndex = -1

class TWPMainViewModel: NSObject {
    let twitterAPI = TWPTwitterAPI.sharedInstance
    
    dynamic var tapCount: NSInteger = 0
    dynamic var tweets: NSArray = []
    
    var inputtingTweet:String?
    var selectingIndex:Int = kNotSelectIndex
    
    // because to feed update singal called many times, signal set a variable.
    private var _feedUpdateButtonSignal: RACSignal?
    
    // MARK: - Deinit
    deinit {
        println("MainViewModel deinit")
    }
    
    // MARK: - Initializer
    override init() {
        super.init();
        
    }
    
    // MARK: - Public Methods
    func selectingTweetScreenName() -> String? {
        if self.selectingIndex == kNotSelectIndex {
            return nil
        }
        var selectingTweet:TWPTweet = self.tweets[self.selectingIndex] as! TWPTweet
        return selectingTweet.user?.screenName!
    }

    // MARK: - Private Methods

    
    // MARK: - RACCommands
    // oauth
    var oauthButtonCommand: RACCommand {
        return RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            
            return self!.oauthButtonSignal
        })
    }
    var oauthButtonSignal: RACSignal {
        
        return RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
            self!.twitterAPI.twitterAuthorizeWithOAuth().subscribeNext({ (next) -> Void in
                
                self!.tweets = next as! NSArray
                
                }, error: { (error) -> Void in
                    subscriber.sendError(error)
                }, completed: { () -> Void in
                    subscriber.sendNext(nil)
                    subscriber.sendCompleted()
            })
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }

    // account
    var accountButtonCommand: RACCommand {
        return RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return self!.accountButtonSignal
        })
    }
    var accountButtonSignal: RACSignal {
        return RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
            self!.twitterAPI.twitterAuthorizeWithAccount().subscribeNext({ (next) -> Void in
                
                self!.tweets = next as! NSArray
                
                subscriber.sendNext(next)
            }, error: { (error) -> Void in
                subscriber.sendError(error)
            }, completed: { () -> Void in
                subscriber.sendNext(nil)
                subscriber.sendCompleted()
            })
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }
    
    // feed update
    var feedUpdateButtonCommand: RACCommand {
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