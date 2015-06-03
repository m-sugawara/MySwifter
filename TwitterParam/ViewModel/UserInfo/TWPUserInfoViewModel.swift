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
   
    override init() {
        super.init()
    }
    
    func getUserInfoSignal() -> RACSignal! {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAPI.getMyUser()?.subscribeNext({ (next) -> Void in
                subscriber.sendNext(next)
            }, error: { (error) -> Void in
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
}
