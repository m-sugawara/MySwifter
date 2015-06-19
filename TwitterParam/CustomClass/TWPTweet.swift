//
//  TWPTweet.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/02.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

class TWPTweet {
    var tweetID: String
    var text: String?
    var profileImageUrl: NSURL?
    
    init(tweetID: String, text: String?, profileImageUrl: String?) {
        self.tweetID = tweetID
        self.text = text
        self.profileImageUrl = NSURL(string: profileImageUrl!)
    }
    
    var profileImageUrlString : String? {
        return profileImageUrl?.absoluteString
    }
    
}