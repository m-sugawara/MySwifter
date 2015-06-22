//
//  TWPUser.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/20.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import SwifteriOS

class TWPUser:NSObject {
    var userID: String?
    var name: String?
    var screenName: String?
    var screenNameWithAt: String?
    var profileImageUrl: NSURL?
    
    override init() {
        super.init()
    }
    
    init(userID: String?, name: String?, screenName: String?, profileImageUrl: String?) {
        self.userID = userID
        self.name = name
        self.screenName = screenName
        self.screenNameWithAt = "@" + screenName!
        self.profileImageUrl = NSURL(string: profileImageUrl!)
    }
    
    convenience init(dictionary: Dictionary<String, JSONValue>) {
        self.init(
            userID: dictionary["id_str"]?.string,
            name: dictionary["name"]?.string,
            screenName: dictionary["screen_name"]?.string,
            profileImageUrl: dictionary["profile_image_url"]?.string
        )
    }
    
    var profileImageUrlString : String? {
        return profileImageUrl?.absoluteString
    }
    
}