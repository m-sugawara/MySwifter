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
    
    class func saveUserToken(data: SwifterCredential.OAuthAccessToken) -> Bool {
        
        var userDefaults = NSUserDefaults.standardUserDefaults()
        println(data)
        userDefaults.setObject(TWPUserAccountType.oAuth.hashValue, forKey: kKeyForUserAccountType)
        userDefaults.setObject(data.key, forKey: kKeyForUserTokenKey)
        userDefaults.setObject(data.secret, forKey: kKeyForUserTokenSecret)
        userDefaults.setObject(data.screenName, forKey: kKeyForUserTokenScreenName)
        userDefaults.setObject(data.userID, forKey: kKeyForUserTokenUserID)
        userDefaults.setObject(data.verifier, forKey: kKeyForUserTokenVerifier)
        userDefaults.synchronize()
        
        return true
    }
    
    class func saveUserAccount(account: ACAccount) -> Bool {
        
        let userID:String = account.valueForKeyPath("properties.user_id")! as! String
        println("userID:\(userID)")
        
        var userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(TWPUserAccountType.acAccount.hashValue, forKey: kKeyForUserAccountType)
        userDefaults.setObject(nil, forKey: kKeyForUserTokenKey)
        userDefaults.setObject(nil, forKey: kKeyForUserTokenSecret)
        userDefaults.setObject(userID, forKey: kKeyForUserTokenUserID)
        userDefaults.setObject(account.username, forKey: kKeyForUserTokenScreenName)
        userDefaults.setObject(nil, forKey: kKeyForUserTokenVerifier)
        userDefaults.synchronize()
        
        return true
    }
    
    class func removeUserToken() -> Bool {
        var userDefaults = NSUserDefaults.standardUserDefaults()
        
        userDefaults.removeObjectForKey(kKeyForUserTokenKey)
        userDefaults.removeObjectForKey(kKeyForUserTokenSecret)
        userDefaults.removeObjectForKey(kKeyForUserTokenUserID)
        userDefaults.removeObjectForKey(kKeyForUserTokenScreenName)
        userDefaults.removeObjectForKey(kKeyForUserTokenVerifier)
        userDefaults.synchronize()
        
        return true
    }
    
    class func fetchUserToken() -> SwifterCredential? {
        
        var userDefaults = NSUserDefaults.standardUserDefaults()
        
        if var tokenKey = userDefaults.objectForKey(kKeyForUserTokenKey) as? String {
            if var tokenSecret = userDefaults.objectForKey(kKeyForUserTokenSecret) as? String {
                
                var access = SwifterCredential.OAuthAccessToken(key: tokenKey, secret: tokenSecret)
                return SwifterCredential(accessToken: access)
            }
        }
        return nil
    }
    
    class func currentUserID() -> String? {
        var userDefaults = NSUserDefaults.standardUserDefaults()
        if userDefaults.objectForKey(kKeyForUserTokenUserID) == nil {
            return nil
        }
        
        var userID = userDefaults.objectForKey(kKeyForUserTokenUserID) as! String?
        return userID
    }
    
    class func currentUser() -> TWPUser? {
        let currentUserID = TWPUserHelper.currentUserID()
        if currentUserID == nil {
            return nil
        }
        
        var currentUser = TWPUserList.sharedInstance.findUserByUserID(currentUserID!)
        return currentUser
    }
}