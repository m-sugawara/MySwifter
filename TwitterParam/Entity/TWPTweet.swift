//
//  TWPTweet.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/02.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import SwifteriOS

struct TWPTweet {
    let tweetId: String
    let text: String?
    let user: TWPUser?
    var retweeted: Bool
    var retweetCount: Int
    var favorited: Bool
    var favoriteCount: Int
    let createdAt: Date?

    init(
        tweetId: String,
        text: String?,
        user: TWPUser?,
        retweeted: Bool = false,
        retweetCount: Int = 0,
        favorited: Bool = false,
        favoriteCount: Int = 0,
        createdAt: Date? = nil
    ) {
        self.tweetId = tweetId
        self.text = text
        self.user = user
        self.retweeted = retweeted
        self.retweetCount = retweetCount
        self.favorited = favorited
        self.favoriteCount = favoriteCount
        self.createdAt = createdAt
    }

    init(status: JSON, user: TWPUser?) {
        self.init(
            tweetId: status["id_str"].string ?? "",
            text: status["text"].string,
            user: user,
            retweeted: status["retweeted"].bool ?? false,
            retweetCount: status["retweet_count"].integer ?? 0,
            favorited: status["favorited"].bool ?? false,
            favoriteCount: status["favorite_count"].integer ?? 0,
            createdAt: status["created_at"].string?.toSpecificFormatDate()
        )
    }

    init(dictionary: [String: JSON], user: TWPUser?) {
        self.init(
            tweetId: dictionary["id_str"]!.string ?? "",
            text: dictionary["text"]!.string,
            user: user,
            retweeted: dictionary["retweeted"]!.bool ?? false,
            retweetCount: dictionary["retweet_count"]?.integer ?? 0,
            favorited: dictionary["favorited"]!.bool ?? false,
            favoriteCount: dictionary["favorite_count"]?.integer ?? 0,
            createdAt: dictionary["created_at"]?.string?.toSpecificFormatDate()
        )
    }
}

extension String {
    fileprivate func toSpecificFormatDate() -> Date? {
        let specificFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        let locale = "en_US"
        return self.date(with: specificFormat, localeIdentifier: locale)
    }
}
