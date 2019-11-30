//
//  TWPUser.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/20.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import SwifteriOS

struct TWPUser {
    let userId: String?
    let name: String?
    let screenName: String?
    let screenNameWithAt: String?
    let profileImageUrl: URL?
    var following: Bool
    let friendsCount: Int?
    let followersCount: Int?

    init(userId: String?, name: String?, screenName: String?, profileImageUrl: String?, following: Bool?, friendsCount: Int?, followersCount: Int?) {
        self.userId = userId
        self.name = name
        self.screenName = screenName
        self.screenNameWithAt = "@" + screenName!
        self.profileImageUrl = URL(string: profileImageUrl!)
        self.following = following ?? false
        self.friendsCount = friendsCount
        self.followersCount = followersCount
    }

    init(dictionary: Dictionary<String, JSON>) {
        self.init(
            userId:          dictionary["id_str"]?.string,
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

extension TWPUser: Equatable {}
