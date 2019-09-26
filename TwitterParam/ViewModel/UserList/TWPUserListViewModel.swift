//
//  TWPUserListViewModel.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/28.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import ReactiveSwift

class TWPUserListViewModel: NSObject {
    let twitterAPI = TWPTwitterAPI.sharedInstance
    var selectingUserID: String?
    var userList:Array<TWPUser> = []
   
    // MARK: - Signals
    func getUserList() -> SignalProducer<Void, Error>? {
        return SignalProducer<Void, Error> { [weak self] innerObserver, _ in
            guard let self = self else { return }
            self.twitterAPI.getFriendListWithID(self.selectingUserID!,count: 20)?.subscribeNext({ (resultUsers) -> Void in
                self!.userList = resultUsers as! Array<TWPUser>
            }, error: { (error) -> Void in
                innerObserver.sendError(error)
            }, completed: { () -> Void in
                innerObserver.send(value: ())
                innerObserver.sendCompleted()
            })
        }
    }
}
