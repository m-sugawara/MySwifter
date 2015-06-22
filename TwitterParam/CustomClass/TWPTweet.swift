//
//  TWPTweet.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/02.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import SwifteriOS

class TWPTweet:NSObject {
    var tweetID: String?
    var text: String?
    var user: TWPUser?
    var retweeted: Bool?
    var retweetCount: Int?
    var favorited: Bool?
    var favoriteCount: Int?
    var createdAt: NSDate?
    
    init(tweetID: String?, text: String?, user: TWPUser?, retweeted: Bool? = nil, retweetCount: Int? = nil, favorited: Bool? = nil, favoriteCount: Int? = nil, createdAt: NSDate? = nil) {
        self.tweetID = tweetID
        self.text = text
        self.user = user
        self.retweeted = retweeted
        self.retweetCount = retweetCount
        self.favorited = favorited
        self.favoriteCount = favoriteCount
        self.createdAt = createdAt
    }
    
    convenience init(status: JSONValue, user: TWPUser?) {
        self.init(tweetID: status["id_str"].string,
            text: status["text"].string,
            user: user,
            retweeted: status["retweeted"].bool,
            retweetCount: status["retweet_count"].integer,
            favorited: status["favorited"].bool,
            favoriteCount: status["favorite_count"].integer,
            createdAt: status["created_at"].string?.dateWithFormat("EEE MMM dd HH:mm:ss Z yyyy", localeIdentifier: "en_US")
        )
    }
    
    convenience init(dictionary: Dictionary<String, JSONValue>, user: TWPUser?) {
        self.init(tweetID: dictionary["id_str"]!.string,
            text: dictionary["text"]!.string,
            user: user,
            retweeted: dictionary["retweeted"]!.bool,
            retweetCount: dictionary["retweet_count"]?.integer,
            favorited: dictionary["favorited"]!.bool,
            favoriteCount: dictionary["favorite_count"]?.integer,
            createdAt: dictionary["created_at"]!.string?.dateWithFormat("EEE MMM dd HH:mm:ss Z yyyy", localeIdentifier: "en_US")
        )
    }
    
}