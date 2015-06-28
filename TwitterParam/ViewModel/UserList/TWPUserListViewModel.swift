//
//  TWPUserListViewModel.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/28.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveCocoa

class TWPUserListViewModel: NSObject {
    let twitterAPI = TWPTwitterAPI.sharedInstance
    var selectingUserID: String?
    var userList:Array<TWPUser> = []
   
    // MARK: - Signals
    func getUserList() -> RACSignal? {
        return RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
            self?.twitterAPI.getFriendListWithID(self!.selectingUserID!,count: 20)?.subscribeNext({ (resultUsers) -> Void in
                self!.userList = resultUsers as! Array<TWPUser>
            }, error: { (error) -> Void in
                subscriber.sendError(error)
            }, completed: { () -> Void in
                subscriber.sendNext(nil)
                subscriber.sendCompleted()
            })
            
            return RACDisposable()
        })
    }
}
