//
//  TWPUser.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/20.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import SwifteriOS

class TWPUser: NSObject {
    var userID: String?
    var name: String?
    var screenName: String?
    var screenNameWithAt: String?
    var profileImageUrl: URL?
    var following:Bool?
    var friendsCount: Int?
    var followersCount: Int?
    
    override init() {
        super.init()
    }
    
    init(userID: String?, name: String?, screenName: String?, profileImageUrl: String?, following: Bool?, friendsCount: Int?, followersCount: Int?) {
        self.userID = userID
        self.name = name
        self.screenName = screenName
        self.screenNameWithAt = "@" + screenName!
        self.profileImageUrl = URL(string: profileImageUrl!)
        self.following = following
        self.friendsCount = friendsCount
        self.followersCount = followersCount
    }
    
    convenience init(dictionary: Dictionary<String, JSON>) {
        self.init(
            userID:          dictionary["id_str"]?.string,
            name:            dictionary["name"]?.string,
            screenName:      dictionary["screen_name"]?.string,
            profileImageUrl: dictionary["profile_image_url"]?.string,
            following:       dictionary["following"]?.bool,
            friendsCount:    dictionary["friends_count"]?.integer,
            followersCount:  dictionary["followers_count"]?.integer
        )
    }
    
    var profileImageUrlString : String? {
        return profileImageUrl?.absoluteString
    }
    
}
