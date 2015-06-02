//
//  TWPUserHelper.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/02.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

import SwifteriOS

class TWPUserHelper {
    
    static let kKeyForUserTokenKey = "userTokenKey"
    static let kKeyForUserTokenSecret = "userTokenSecret"
    static let kKeyForUserTokenScreenName = "userTokenScreenName"
    static let kKeyForUserTokenUserID = "userTokenUserID"
    static let kKeyForUserTokenVerifier = "userTokenVerifier"
    
    class func saveUserToken(data: SwifterCredential.OAuthAccessToken) -> Bool {
        
        var userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(data.key, forKey: kKeyForUserTokenKey)
        userDefaults.setObject(data.secret, forKey: kKeyForUserTokenSecret)
        userDefaults.setObject(data.screenName, forKey: kKeyForUserTokenScreenName)
        userDefaults.setObject(data.userID, forKey: kKeyForUserTokenUserID)
        userDefaults.setObject(data.verifier, forKey: kKeyForUserTokenVerifier)
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
    
    class func fetchUserQData() -> NSDictionary {
        var userDefaults = NSUserDefaults.standardUserDefaults()
        var data: NSMutableDictionary = NSMutableDictionary()
        data["screenName"] = userDefaults.objectForKey(kKeyForUserTokenScreenName) as! String?
        data["userID"] = userDefaults.objectForKey(kKeyForUserTokenUserID) as! String?
        return data
    }
}