//
//  TWPUserHelper.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/02.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation
import Accounts

import SwifteriOS

enum TWPUserAccountType {
    case oAuth
    case acAccount
}

class TWPUserHelper {
    
    static let kKeyForUserAccountType = "userAccountType"
    
    static let kKeyForUserTokenKey = "userTokenKey"
    static let kKeyForUserTokenSecret = "userTokenSecret"
    static let kKeyForUserTokenScreenName = "userTokenScreenName"
    static let kKeyForUserTokenUserID = "userTokenUserID"
    static let kKeyForUserTokenVerifier = "userTokenVerifier"

    private static var userDefaults = UserDefaults.standard
    
    class func saveUserToken(data: Credential.OAuthAccessToken) -> Bool {
        userDefaults.set(TWPUserAccountType.oAuth.hashValue, forKey: kKeyForUserAccountType)
        userDefaults.set(data.key, forKey: kKeyForUserTokenKey)
        userDefaults.set(data.secret, forKey: kKeyForUserTokenSecret)
        userDefaults.set(data.screenName, forKey: kKeyForUserTokenScreenName)
        userDefaults.set(data.userID, forKey: kKeyForUserTokenUserID)
        userDefaults.set(data.verifier, forKey: kKeyForUserTokenVerifier)
        
        return true
    }
    
    class func saveUserAccount(account: ACAccount) -> Bool {
        guard let userId = account.value(forKeyPath: "properties.user_id") as? String else { return false }

        userDefaults.set(TWPUserAccountType.acAccount.hashValue, forKey: kKeyForUserAccountType)
        userDefaults.set(nil, forKey: kKeyForUserTokenKey)
        userDefaults.set(nil, forKey: kKeyForUserTokenSecret)
        userDefaults.set(userId, forKey: kKeyForUserTokenUserID)
        userDefaults.set(account.username, forKey: kKeyForUserTokenScreenName)
        userDefaults.set(nil, forKey: kKeyForUserTokenVerifier)
        
        return true
    }
    
    class func removeUserToken() -> Bool {
        userDefaults.removeObject(forKey: kKeyForUserTokenKey)
        userDefaults.removeObject(forKey: kKeyForUserTokenSecret)
        userDefaults.removeObject(forKey: kKeyForUserTokenUserID)
        userDefaults.removeObject(forKey: kKeyForUserTokenScreenName)
        userDefaults.removeObject(forKey: kKeyForUserTokenVerifier)
        
        return true
    }
    
    class func fetchUserToken() -> Credential? {
        guard let tokenKey = userDefaults.object(forKey: kKeyForUserTokenKey) as? String, let tokenSecret = userDefaults.object(forKey: kKeyForUserTokenSecret) as? String else { return nil }

        let access = Credential.OAuthAccessToken(key: tokenKey, secret: tokenSecret)
        return Credential(accessToken: access)
    }
    
    class func currentUserID() -> String? {
        guard let userId = userDefaults.object(forKey: kKeyForUserTokenUserID) as? String else { return nil }
        return userId
    }
    
    class func currentUser() -> TWPUser? {
        guard let currentUserID = TWPUserHelper.currentUserID() else {
            return nil
        }
        
        let currentUser = TWPUserList.shared.findUser(by: currentUserID)
        return currentUser
    }
}
