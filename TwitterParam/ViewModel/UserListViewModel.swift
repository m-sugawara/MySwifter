//
//  UserListViewModel.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/28.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import ReactiveSwift

class UserListViewModel: NSObject {

    private(set) var userList: [User] = []

    func user(at index: Int) -> User? {
        guard index < userList.count else { return nil }
        return userList[index]
    }

    // MARK: - Signals
    func getUserList(with userId: String) -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, _ in
            TwitterAPI.shared.getFriendList(
                with: userId,
                count: 20
            ).startWithResult { result in
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
