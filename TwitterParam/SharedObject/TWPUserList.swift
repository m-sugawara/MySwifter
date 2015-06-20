//
//  TWPUserList.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/03.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

final class TWPUserList:NSObject {
    
    var users:Array<TWPUser> = []
    
    // MARK: - Singleton
    static let sharedInstance = TWPUserList()
    
    // MARK: - Initializer
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    func appendUser(_user:TWPUser) {
        if self.findUserByUserID(_user.userID!) != nil {
            self.updateUser(_user)
        }
        else {
            self.users.append(_user)
        }
    }
    
    func updateUser(_user:TWPUser) {
        var i = 0
        for user in self.users {
            if (_user.userID == user.userID) {
                self.users[i] = _user
                return
            }
            i++
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