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

    var selectingUserID: String?
    var userList: [TWPUser] = []
   
    // MARK: - Signals
    func getUserList() -> SignalProducer<Void, Error>? {
        return SignalProducer<Void, Error> { observer, _ in
            TWPTwitterAPI.shared.getFriendList(
                with: self.selectingUserID!,
                count: 20
            ).startWithResult{ result in
                switch result {
                case .success(let users):
                    self.userList = users
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }
        }
    }
}
