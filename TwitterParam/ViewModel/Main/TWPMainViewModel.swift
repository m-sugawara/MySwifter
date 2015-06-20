//
//  TWPMainViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

class TWPMainViewModel: NSObject {
    let twitterAPI = TWPTwitterAPI.sharedInstance
    
    dynamic var tapCount: NSInteger = 0
    dynamic var tweets: NSArray = []
    
    private var _feedUpdateButtonSignal: RACSignal?
    
    // MARK: - Initializer
    override init() {
        super.init();
        
    }
    
    // MARK: - Public Methods
    func postStatusRetweetWithIndex(index: Int, success: ()->Void, failure: (error:NSError)->Void) {
        var tweet: TWPTweet = self.tweets[index] as! TWPTweet
        
        // if haven't retweeted yet, try to retweet
        if (tweet.retweeted != true) {
            self.twitterAPI.postStatusRetweetWithID(tweet.tweetID!,
                trimUser: false,
                success: { (status) -> Void in
                    (self.tweets[index] as! TWPTweet).retweeted = true
                    success()
                }) { (error) -> Void in
                    failure(error: error)
            }
        }
        // if already have retweeted, destroy retweet
        else {
            var retweetID:String?
            
            // 1. get current user's retweetID
            self.twitterAPI.getCurrentUserRetweetIDWithID(tweet.tweetID!)?.subscribeNext({ (next) -> Void in
                    // if successed, current user's retweetID
                    retweetID = next as? String
                }, error: { (error) -> Void in
                    failure(error: error)
                }, completed: { () -> Void in
                    // 2. destroy current user's retweet
                    self.twitterAPI.postStatusesDestroyWithID(retweetID!,
                        trimUser: false,
                        success: { (status) -> Void in
                            // 3. this tweet become be NOT retweeted
                            (self.tweets[index] as! TWPTweet).retweeted = false
                            success()
                        }, failure: { (error) -> Void in
                            failure(error: error)
                    })
                })
        }
        
        
    }

    // MARK: - Private Methods

    
    // MARK: - RACCommands
    var oauthButtonCommand: RACCommand {
        return RACCommand(signalBlock: { (input) -> RACSignal! in
            
            return self.oauthButtonSignal
        })
    }
    var oauthButtonSignal: RACSignal {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAPI.twitterAuthorizeWithOAuth().subscribeNext({ (next) -> Void in
                
                self.tweets = next as! NSArray
                
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

    var accountButtonCommand: RACCommand {
        return RACCommand(signalBlock: { (input) -> RACSignal! in
            return self.accountButtonSignal
        })
    }
    var accountButtonSignal: RACSignal {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAPI.twitterAuthorizeWithAccount().subscribeNext({ (next) -> Void in
                
                self.tweets = next as! NSArray
                
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
    
    var feedUpdateButtonCommand: RACCommand {
        return RACCommand(signalBlock: { (input) -> RACSignal! in
            return self.feedUpdateButtonSignal()
        })
    }
    func feedUpdateButtonSignal() -> RACSignal {
        if (_feedUpdateButtonSignal != nil) {
            return _feedUpdateButtonSignal!
        }
        _feedUpdateButtonSignal =  RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAPI.getStatusesHomeTimelineWithCount(20)?.subscribeNext({ (next) -> Void in
                self.tweets = next as! NSArray
                }, error: { (error) -> Void in
                    subscriber.sendError(error)
                }, completed: { () -> Void in
                    subscriber.sendNext(nil)
                    subscriber.sendCompleted()
            })
            
            return nil
        })
        
        return _feedUpdateButtonSignal!
    }
}