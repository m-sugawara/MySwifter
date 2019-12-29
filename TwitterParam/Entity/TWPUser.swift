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
    let userId: String
    let name: String?
    let screenName: String
    let profileImageUrl: URL?
    var following: Bool
    let friendsCount: Int
    let followersCount: Int

    init(userId: String,
         name: String = "",
         screenName: String = "",
         profileImageUrl: String = "",
         following: Bool = false,
         friendsCount: Int = 0,
         followersCount: Int = 0
    ) {
        self.userId = userId
        self.name = name
        self.screenName = screenName
        self.profileImageUrl = URL(string: profileImageUrl)
        self.following = following
        self.friendsCount = friendsCount
        self.followersCount = followersCount
    }

    init(dictionary: [String: JSON]) {
        self.init(
            userId:          dictionary["id_str"]?.string ?? "",
            name:            dictionary["name"]?.string ?? "",
            screenName:      dictionary["screen_name"]?.string ?? "",
            profileImageUrl: dictionary["profile_image_url"]?.string ?? "",
            following:       dictionary["following"]?.bool ?? false,
            friendsCount:    dictionary["friends_count"]?.integer ?? 0,
            followersCount:  dictionary["followers_count"]?.integer ?? 0
        )
    }

    var screenNameWithAt: String {
        return (screenName.isEmpty) ? "" : "@" + screenName
    }

    var profileImageUrlString: String? {
        return profileImageUrl?.absoluteString
    }

    var isSelf: Bool {
        return userId == TWPUserHelper.currentUserId()
    }

}

extension TWPUser: Equatable {}
