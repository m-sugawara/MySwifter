//
//  TWPUserList.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/03.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

final class TWPUserList:NSObject {

    var users: Array<TWPUser> = []

    // MARK: - Singleton
    static let shared = TWPUserList()

    // MARK: - Initializer
    private override init() {
        super.init()
    }

    // MARK: - Public Methods
    func appendUser(_ user:TWPUser) {
        if self.findUser(by: user.userId!) != nil {
            self.updateUser(user)
        } else {
            self.users.append(user)
        }
    }

    func updateUser(_ target: TWPUser) {
        self.users = users.map { user in
            guard user == target else { return user }
            return target
        }
    }

    func findUser(by userId:String) -> TWPUser? {
        return users.filter { $0.userId == userId }.first
    }

    func setFollowing(_ following: Bool, toUserId: String) {
        self.users = users.map { user in
            guard user.userId == toUserId else { return user }
            var mutableUser = user
            mutableUser.following = following
            return mutableUser
        }
    }

}
