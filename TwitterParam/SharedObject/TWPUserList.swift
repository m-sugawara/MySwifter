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
    static let sharedInstance = TWPUserList()
    
    // MARK: - Initializer
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    func appendUser(_ user:TWPUser) {
        if self.findUserByUserID(userID: user.userID!) != nil {
            self.updateUser(user)
        }
        else {
            self.users.append(user)
        }
    }
    
    func updateUser(_ target: TWPUser) {
        var i = 0
        for user in self.users {
            if (target.userID == user.userID) {
                self.users[i] = target
                return
            }
            i += 1
        }
    }
    
    func findUserByUserID(userID:String) -> TWPUser? {
        for user in self.users {
            if (user.userID == userID) {
                return user
            }
        }
        return nil
    }
    
    
}
