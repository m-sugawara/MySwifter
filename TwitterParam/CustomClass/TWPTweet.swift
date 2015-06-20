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
    
    init(tweetID: String?, text: String?, user: TWPUser?, retweeted: Bool?) {
        self.tweetID = tweetID
        self.text = text
        self.user = user
        self.retweeted = retweeted
    }
    
    convenience init(status: JSONValue, user: TWPUser?) {
        self.init(tweetID: status["id_str"].string,
            text: status["text"].string,
            user: user,
            retweeted: status["retweeted"].bool
        )
    }
    
    convenience init(dictionary: Dictionary<String, JSONValue>, user: TWPUser?) {
        self.init(tweetID: dictionary["id_str"]!.string,
            text: dictionary["text"]!.string,
            user: user,
            retweeted: dictionary["retweeted"]!.bool
        )
    }
    
}