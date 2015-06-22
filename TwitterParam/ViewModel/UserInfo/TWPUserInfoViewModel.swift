//
//  TWPUserInfoViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/03.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

class TWPUserInfoViewModel: NSObject {
    let twitterAPI = TWPTwitterAPI.sharedInstance
    
    var userID:String = ""
    var user:TWPUser = TWPUser()
    
    var favoriteList:Array<TWPTweet>?
    
    dynamic var tweets: NSArray = []

    // MARK: - Initializer
    override init() {
        super.init()
    }
    
    // MARK: - Signals
    func getUserInfoSignal() -> RACSignal! {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAPI.getUsersShowWithUserID(self.userID)?.subscribeError({ (error) -> Void in
                subscriber.sendError(error)
            }, completed: { () -> Void in
                // find User
                self.user = TWPUserList.sharedInstance.findUserByUserID(self.userID)!
                
                subscriber.sendCompleted()
            })
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }
    
    func getUserTimelineSignal() -> RACSignal! {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAPI.getStatusesUserTimelineWithUserID(self.userID, count: 20)?.subscribeNext({ (next) -> Void in
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
    
    // FIXME: - dummy method
    func getUserImageList() -> RACSignal! {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            NSThread.sleepForTimeInterval(0.5)
            var dummy = TWPTweet(tweetID: "", text: "not implemented", user: self.user, retweeted: false, favorited: false)
            self.tweets = [dummy]
            
            subscriber.sendNext(nil)
            subscriber.sendCompleted()
            
            return RACDisposable()
        })
    }
    
    func getUserFavoritesList() -> RACSignal! {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            // if already have got list, return it.
            if self.favoriteList != nil {
                self.tweets = self.favoriteList!
                subscriber.sendNext(nil)
                subscriber.sendCompleted()
            }
            // if not, try to get favorites list
            else {
                self.twitterAPI.getFavoritesListWithUserID(self.userID, count: 20)?.subscribeNext({ (next) -> Void in
                    self.favoriteList = next as? Array
                    self.tweets = self.favoriteList!
                    }, error: { (error) -> Void in
                        subscriber.sendError(error)
                    }, completed: { () -> Void in
                        subscriber.sendNext(nil)
                        subscriber.sendCompleted()
                })
            }
            
            return RACDisposable()
        })
    }
}
