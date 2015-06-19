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
    
    dynamic var tweets: NSArray = []

    // MARK: - Initializer
    override init() {
        super.init()
    }
    
    // MARK: - Signals
    func getUserInfoSignal() -> RACSignal! {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAPI.getMyUser()?.subscribeError({ (error) -> Void in
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
}
