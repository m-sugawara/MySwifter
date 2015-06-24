//
//  TWPTweetDetailViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/19.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

class TWPTweetDetailViewModel: NSObject {
    let twitterAPI = TWPTwitterAPI.sharedInstance
    
    var tweetID = ""
    var tweet:TWPTweet?
    
    // MARK: - Deinit
    deinit {
        println("TweetDetailViewModel deinit")
    }
    
    func getTweetSignal() -> RACSignal? {
        
        return RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
            self!.twitterAPI.getStatuesShowWithID(self!.tweetID)?.subscribeNext({ (next) -> Void in
                self!.tweet = (next as? TWPTweet?)!
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
    
    
}
